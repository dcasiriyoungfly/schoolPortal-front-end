from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from database import connect_db, close_db, get_db
from seed import seed_database
from routers import auth_router, teachers, students, classes, subjects, marks, admin, reports
from routers import applications, mark_config


@asynccontextmanager
async def lifespan(app: FastAPI):
    # ── Startup ───────────────────────────────────────────────────────────────
    await connect_db()
    db = get_db()
    await seed_database(db)
    yield
    # ── Shutdown ──────────────────────────────────────────────────────────────
    await close_db()


app = FastAPI(
    title="School Portal API",
    description="High School Results Management System — REST API (MongoDB)",
    version="2.0.0",
    lifespan=lifespan,
    redirect_slashes=False,
)

# ── CORS ─────────────────────────────────────────────────────────────────────
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ── Routers ───────────────────────────────────────────────────────────────────
app.include_router(auth_router.router, prefix="/auth",     tags=["Auth"])
app.include_router(teachers.router,    prefix="/teachers", tags=["Teachers"])
app.include_router(students.router,    prefix="/students", tags=["Students"])
app.include_router(classes.router,     prefix="/classes",  tags=["Classes"])
app.include_router(subjects.router,    prefix="/subjects", tags=["Subjects"])
app.include_router(marks.router,       prefix="/marks",    tags=["Marks"])
app.include_router(admin.router,       prefix="/admin",    tags=["Admin"])
app.include_router(reports.router,       prefix="/reports",       tags=["Reports"])
app.include_router(applications.router, prefix="/applications",  tags=["Applications"])
app.include_router(mark_config.router,  prefix="/mark-config",   tags=["MarkConfig"])


@app.get("/", tags=["Health"])
def root():
    return {"status": "ok", "message": "School Portal API is running (MongoDB)"}
