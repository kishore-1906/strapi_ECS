from flask import Flask, request, render_template
import boto3
import pymysql

app = Flask(__name__)

s3 = boto3.client('s3')
bucket_name = "your-unique-s3-bucket-name"

rds_host = "your-db-endpoint"
db_user = "admin"
db_password = "password"
db_name = "jobapp"

conn = pymysql.connect(host=rds_host, user=db_user, passwd=db_password, db=db_name)

@app.route("/", methods=["GET", "POST"])
def index():
    if request.method == "POST":
        name = request.form["name"]
        email = request.form["email"]
        phone = request.form["phone"]
        resume = request.files["resume"]
        s3.upload_fileobj(resume, bucket_name, resume.filename)
        with conn.cursor() as cur:
            cur.execute("CREATE TABLE IF NOT EXISTS applicants (name VARCHAR(255), email VARCHAR(255), phone VARCHAR(20));")
            cur.execute("INSERT INTO applicants (name, email, phone) VALUES (%s, %s, %s)", (name, email, phone))
            conn.commit()
        return "Application submitted successfully."
    return render_template("index.html")

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)

