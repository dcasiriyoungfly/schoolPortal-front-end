# School Portal Front End

This repository contains a school portal project with a FastAPI backend and a Flutter frontend.

## Project Structure

- `backend/` - Python FastAPI backend
- `schoolwebsite/` - Flutter frontend application
- `ExcellenceHighSchool_Portal_Documentation.docx` - project documentation file
- `ExcellenceHighSchool_Portal_Documentation_v1.1.docx` - updated documentation file

## Backend

The backend is built with FastAPI and uses MongoDB as its database.

### Requirements

- Python 3.11+ recommended
- MongoDB

### Install dependencies

From the `backend/` directory:

```bash
python -m pip install -r requirements.txt
```

### Run the backend

From the `backend/` directory:

```bash
python -m uvicorn main:app --reload --port 8000
```

### Local URLs

- API: `http://127.0.0.1:8000`
- Swagger docs: `http://127.0.0.1:8000/docs`

### Database

The backend expects a MongoDB database named `school_portal` and seed data loaded for users, students, teachers, classes, and marks.

## Frontend

The frontend is a Flutter project located in `schoolwebsite/`.

### Flutter requirements

- Flutter SDK
- Dart SDK
- A supported device or emulator

### Install dependencies

From the `schoolwebsite/` directory:

```bash
flutter pub get
```

### Run the app

From the `schoolwebsite/` directory:

```bash
flutter run
```

## Notes

- The frontend uses `http`, `file_picker`, and `cupertino_icons` packages.
- The backend uses FastAPI, Uvicorn, Motor, PyMongo, python-jose, bcrypt, pydantic, python-multipart, and python-dotenv.
- There is a `schoolwebsite/README.md` that contains the Flutter starter project README.

## Helpful Files

- `backend/requirements.txt` - backend Python dependencies
- `schoolwebsite/pubspec.yaml` - frontend Flutter dependencies
- `backend/main.py` - FastAPI application entry point

## Useful commands

> Run from `backend/`

```bash
python -m uvicorn main:app --reload --port 8000
```

> Run from `schoolwebsite/`

```bash
flutter pub get
flutter run
```

## Author

This repository contains the school portal project source code for the backend and the Flutter frontend.
