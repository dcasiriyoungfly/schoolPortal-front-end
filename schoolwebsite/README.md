# schoolwebsite

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.


every student is given a unique Id  so that when you access your portal you enter student Id number and a password to access the  website

the admin panel  has all number of students  at the school and all classess , so  when teachers accesses certain class which they want  to eneter the marks  all the students inthe class appeears 


 the admin should  be able to add a new teacher , why do i have  mrs Banda , Mr Mwale etc  i should have options to add new teacher who comes to the school the assign a subject and class too |||



 each teacher should  have a certain user Id  and when login  there i no need to choose a name , they should eneter a user ID and a  unique password  and also they should  be able to change password , help to do that for  every teacher  who uses the account



  running backend :python -m uvicorn main:app --reload --port 800 

API: http://127.0.0.1:8000
Swagger docs: http://127.0.0.1:8000/docs
Database: MongoDB school_portal with all seed data loaded

 the user IDs are  u0, U1, u2, u3, u4, 
 password = teacher123 or 246
 student password = student123 //// u6



 All default credentials:

Role	User ID	Password
Admin	u0	admin123
Teacher (Mwale)	u1	teacher123
Teacher (Banda)	u2	teacher123
Teacher (Phiri)	u3	teacher123
Teacher (Tembo)	u4	teacher123
Student (Chanda)	u5	student123
Student (Mwansa)	u6	student123
Student (Bupe)	u7	student123



 admin user iD = 5829A /////////////updated version 
 password = admin123

Student Id is C001 zvichienda zvakadaro 

 Option 1 — MongoDB Compass (Visual, easiest)
Open MongoDB Compass from your Start menu
In the connection string box, enter:

mongodb://localhost:27017
Click Connect
You'll see your database listed — look for school_portal


Db password 3sRh5FqmsMFfeYjW

connection method = mongodb+srv://musere2002_db_user:3sRh5FqmsMFfeYjW@cluster0.d0amm88.mongodb.net/?appName=Cluster0



networking URL = schoolportal-front-end.railway.internal


integrate with payment methods like eco cash 
 it should also be showing amount of fees paid by student on the portal also 

 also add position of a student  and there should be a signature in  each student's portal  

 on the landing page there should be an option were students apply for the  school enrollment  anytime  of the year 


 also deleting hard coded teacher and classes 


 

 the add teacher , class button are not working 
 
teacher should be able to search a student in a class  and also for the admin ......students should be numbered also SHOULD BE GIVE LOGIN DETAILS 