import os
from flask import Flask, request, jsonify
from flask_cors import CORS
from pymongo import MongoClient
from pymongo.errors import DuplicateKeyError
from werkzeug.security import check_password_hash, generate_password_hash
from dotenv import load_dotenv

load_dotenv()

app = Flask(__name__)
CORS(app)

mongo_uri = os.getenv("MONGO_URI", "mongodb://localhost:27017/")
db_name = os.getenv("DB_NAME", "university_db")

client = MongoClient(mongo_uri)
db = client[db_name]
collection = db["academic_repository"]
users_collection = db["users"]
try:
    users_collection.create_index("username", unique=True)
except DuplicateKeyError:
    pass

@app.route('/api/register_user', methods=['POST'])
def register_user():
    data = request.json
    if not data:
        return jsonify({"error": "No data provided"}), 400

    name = data.get("name", "").strip()
    username = data.get("username", "").strip()
    password = data.get("password", "")

    if not name or not username or not password:
        return jsonify({"error": "Missing name, username, or password"}), 400

    if len(password) < 6:
        return jsonify({"error": "Password must be at least 6 characters"}), 400

    existing_user = users_collection.find_one({"username": username})
    if existing_user:
        return jsonify({"error": "Username already registered"}), 409

    try:
        users_collection.insert_one({
            "name": name,
            "username": username,
            "password_hash": generate_password_hash(password),
        })
    except DuplicateKeyError:
        return jsonify({"error": "Username already registered"}), 409

    return jsonify({"message": "User registered successfully"}), 201


@app.route('/api/login', methods=['POST'])
def login():
    data = request.json
    if not data:
        return jsonify({"error": "No data provided"}), 400

    username = data.get("username", "").strip()
    password = data.get("password", "")

    if not username or not password:
        return jsonify({"error": "Missing username or password"}), 400

    user = users_collection.find_one({"username": username})
    if not user or not check_password_hash(user.get("password_hash", ""), password):
        return jsonify({"error": "Invalid username or password"}), 401

    return jsonify({
        "message": "Login successful",
        "user": {
            "name": user.get("name", ""),
            "username": user.get("username", ""),
        },
    }), 200

@app.route('/api/add_course', methods=['POST'])
def add_course():
    data = request.json
    if not data:
        return jsonify({"error": "No data provided"}), 400
        
    program_code = data.get("program_code")
    semester = data.get("semester")
    course_data = data.get("course_data")
    semester_duration = data.get("semester_duration")
    semester_duration = data.get("semester_duration")

    if not program_code or not semester or not course_data:
        return jsonify({"error": "Missing program_code, semester, or course_data"}), 400

    # Validate semester range
    try:
        semester = int(semester)
        if semester < 1 or semester > 8:
            return jsonify({"error": "Semester must be between 1 and 8"}), 400
    except ValueError:
        return jsonify({"error": "Semester must be an integer"}), 400

    course_code = course_data.get("course_code")
    if not course_code:
        return jsonify({"error": "course_data must include course_code"}), 400

    # Validate duplicate course_code
    duplicate = collection.find_one({
        "program.program_code": program_code,
        "semesters.courses.course_code": course_code
    })
    
    if duplicate:
        return jsonify({"error": f"Course code {course_code} already exists in program {program_code}"}), 409

    # Insert using $push with positional operator implicitly via array filter or directly if we know index
    # We can use the arrayFilters in update_one to find the exact semester
    update_data = {"$push": {"semesters.$.courses": course_data}}
    if semester_duration:
        update_data["$set"] = {"semesters.$.semester_duration": semester_duration}

    result = collection.update_one(
        {"program.program_code": program_code, "semesters.semester": semester},
        update_data
    )

    if result.matched_count == 0:
        return jsonify({"error": "Program or Semester not found"}), 404

    return jsonify({"message": "Course added successfully"}), 201


@app.route('/api/get_courses/<program_code>/<int:semester>', methods=['GET'])
def get_courses(program_code, semester):
    if semester < 1 or semester > 8:
        return jsonify({"error": "Semester must be between 1 and 8"}), 400

    pipeline = [
        {"$match": {"program.program_code": program_code}},
        {"$unwind": "$semesters"},
        {"$match": {"semesters.semester": semester}},
        {"$project": {"_id": 0, "courses": "$semesters.courses"}}
    ]
    
    results = list(collection.aggregate(pipeline))
    if not results:
        return jsonify({"error": "Program or Semester not found"}), 404
        
    # results[0] will be like {"courses": [...]}
    courses = results[0].get("courses", [])
    return jsonify({"courses": courses}), 200


@app.route('/api/update_course', methods=['PUT'])
def update_course():
    data = request.json
    if not data:
        return jsonify({"error": "No data provided"}), 400
        
    program_code = data.get("program_code")
    semester = data.get("semester")
    course_data = data.get("course_data")

    if not program_code or not semester or not course_data:
        return jsonify({"error": "Missing program_code, semester, or course_data"}), 400

    course_code = course_data.get("course_code")
    if not course_code:
        return jsonify({"error": "course_data must include course_code"}), 400

    update_values = {"semesters.$[sem].courses.$[crs]": course_data}
    if semester_duration:
        update_values["semesters.$[sem].semester_duration"] = semester_duration

    # Update specific course in the array using arrayFilters
    result = collection.update_one(
        {"program.program_code": program_code},
        {"$set": update_values},
        array_filters=[{"sem.semester": semester}, {"crs.course_code": course_code}]
    )

    if result.matched_count == 0:
        return jsonify({"error": "Program not found"}), 404
        
    if result.modified_count == 0:
        return jsonify({"error": "Course not found or no changes made"}), 404

    return jsonify({"message": "Course updated successfully"}), 200


@app.route('/api/delete_course', methods=['DELETE'])
def delete_course():
    data = request.json
    if not data:
        return jsonify({"error": "No data provided"}), 400

    program_code = data.get("program_code")
    semester = data.get("semester")
    course_code = data.get("course_code")

    if not program_code or not semester or not course_code:
        return jsonify({"error": "Missing program_code, semester, or course_code"}), 400

    # Use $pull to remove the course from the array
    result = collection.update_one(
        {"program.program_code": program_code, "semesters.semester": semester},
        {"$pull": {"semesters.$.courses": {"course_code": course_code}}}
    )

    if result.matched_count == 0:
        return jsonify({"error": "Program or Semester not found"}), 404
        
    if result.modified_count == 0:
        return jsonify({"error": "Course not found"}), 404

    return jsonify({"message": "Course deleted successfully"}), 200

if __name__ == '__main__':
    port = int(os.getenv("FLASK_PORT", 5000))
    app.run(debug=True, port=port)
