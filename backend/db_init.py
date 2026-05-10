import os
from pymongo import MongoClient
from dotenv import load_dotenv

load_dotenv()

def initialize_database():
    mongo_uri = os.getenv("MONGO_URI", "mongodb://localhost:27017/")
    db_name = os.getenv("DB_NAME", "university_db")

    client = MongoClient(mongo_uri)
    db = client[db_name]
    collection = db["academic_repository"]

    # 0. Drop the collection to remove old data as requested
    collection.drop()
    print("Dropped old collection to reset data.")

    # 1. Create Indexes
    collection.create_index([
        ("program.program_code", 1),
        ("semesters.semester", 1),
        ("semesters.courses.course_code", 1)
    ])
    print("Ensured indexes are created.")

    # Programs to initialize (CS, IS, and DS)
    programs_data = [
        {
            "program_code": "CS",
            "program_name": "B.Tech Computer Science Engineering",
            "department": "Computer Science Engineering",
            "faculty": "Faculty of Engineering and Technology"
        },
        {
            "program_code": "IS",
            "program_name": "B.Tech Information Science Engineering",
            "department": "Information Science Engineering",
            "faculty": "Faculty of Engineering and Technology"
        },
        {
            "program_code": "DS",
            "program_name": "B.Tech Data Science",
            "department": "Computer Science Engineering",
            "faculty": "Faculty of Engineering and Technology"
        }
    ]

    sample_course = {
        "course_code": "UE24CS101",
        "course_title": "Programming Fundamentals",
        "credits": {
            "L": 3,
            "T": 1,
            "P": 2,
            "total": 6
        },
        "hours_per_week": 5,
        "total_hours": 45,
        "faculty_assignment": {
            "faculty_name": "Dr ABC",
            "section": "A",
            "academic_year": "2025-26"
        },
        "course_aim": "Learn basics of programming",
        "course_objectives": [
            "Understand programming concepts",
            "Develop coding skills"
        ],
        "course_outcomes": [
            {
                "co": "CO1",
                "description": "Understand syntax",
                "bloom": "Remember"
            },
            {
                "co": "CO2",
                "description": "Write programs",
                "bloom": "Apply"
            }
        ],
        "co_po_pso_mapping": [
            {
                "co": "CO1",
                "mapping": {
                    "PO1": 1,
                    "PO2": 2,
                    "PSO1": 1
                }
            }
        ],
        "course_content": [
            {
                "unit": "Introduction",
                "topics": [
                    "Algorithms",
                    "Flowcharts"
                ]
            },
            {
                "unit": "Programming Basics",
                "topics": [
                    "Variables",
                    "Loops",
                    "Functions"
                ]
            }
        ],
        "books": {
            "textbooks": [
                "Programming in C",
                "Python Basics"
            ],
            "references": [
                "https://docs.python.org",
                "https://www.w3schools.com"
            ]
        },
        "teaching_plan": [
            {
                "lecture": 1,
                "topic": "Introduction to Programming"
            },
            {
                "lecture": 2,
                "topic": "Algorithms"
            }
        ],
        "assessment": {
            "structure": {
                "quiz": {
                    "total": 15,
                    "Q1": 5,
                    "Q2": 5,
                    "Q3": 5
                },
                "test": {
                    "total": 25,
                    "T1": 10,
                    "T2": 15
                },
                "assignment": {
                    "total": 20,
                    "A1": 10,
                    "A2": 10
                },
                "cie": 60,
                "see": 40
            },
            "co_distribution": [
                {
                    "co": "CO1",
                    "cie": 10,
                    "see": 8
                }
            ]
        },
        "attainment_targets": {
            "criteria": {
                "level_1": "70% students score C and above",
                "level_2": "60% students score C and above",
                "level_3": "50% students score C and above"
            },
            "co_targets": [
                {
                    "co": "CO1",
                    "target_level": 1
                }
            ]
        },
        "grading": {
            "O": "91+",
            "A+": "81-90",
            "A": "71-80",
            "B+": "61-70",
            "B": "51-60",
            "C": "40-50",
            "D": "<40"
        }
    }

    # Initialize semesters 1 through 8
    # We will add the sample_course to Semester 1
    for p in programs_data:
        semesters_data = []
        for i in range(1, 9):
            courses_list = [sample_course] if i == 1 else []
            semesters_data.append({
                "semester": i,
                "semester_duration": {
                    "teaching_weeks": "1-16",
                    "exam_weeks": "17-18",
                    "result_weeks": "19-20"
                },
                "courses": courses_list
            })
        
        doc = {
            "program": p,
            "semesters": semesters_data
        }
        collection.insert_one(doc)
        print(f"Inserted initialization data with full course structure for program: {p['program_code']}")

    print("Database initialization complete.")

if __name__ == "__main__":
    initialize_database()
