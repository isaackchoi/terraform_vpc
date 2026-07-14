import os
import sys
import psycopg2
from fastapi import FastAPI

app = FastAPI()

# 💡 從環境變數中讀取資料庫連線資訊
DB_HOST = os.getenv("DB_HOST")
DB_NAME = os.getenv("DB_NAME")
DB_USER = os.getenv("DB_USER")
DB_PASSWORD = os.getenv("DB_PASSWORD")

# 🛑 【防爆機制 1】開機嚴格檢查環境變數是否成功注入
# 如果變數是空的，直接列印明確錯誤並優雅退出，避免盲目崩潰
if not all([DB_HOST, DB_NAME, DB_USER, DB_PASSWORD]):
    print(
        f"🚨 錯誤：環境變數未完全注入！目前狀態 -> HOST: {bool(DB_HOST)}, NAME: {bool(DB_NAME)}, USER: {bool(DB_USER)}",
        file=sys.stderr,
    )
    # 這裡我們不拋出異常，讓 FastAPI 至少能把首頁跑起來，方便我們看排查 Log
else:
    print("✅ 成功：所有資料庫環境變數已成功載入！")


@app.get("/")
def read_root():
    return {
        "message": "Welcome to Isaac's Logistics Cloud Center!",
        "status": "Running on AWS ECS Fargate",
        "secured_by": "Application Load Balancer",
    }


# 🚀 新增功能：資料庫連線健康檢查 (Health Check)
@app.get("/db-check")
def check_database_connection():
    # 再次防禦：如果開機時沒拿到環境變數，直接回報
    if not all([DB_HOST, DB_NAME, DB_USER, DB_PASSWORD]):
        return {
            "status": "Failed",
            "message": "Missing database configuration environment variables.",
        }

    try:
        # connect_timeout 稍微拉長到 5 秒，給雲端網路多一點緩衝
        connection = psycopg2.connect(
            host=DB_HOST,
            database=DB_NAME,
            user=DB_USER,
            password=DB_PASSWORD,
            connect_timeout=5,
        )
        cursor = connection.cursor()
        cursor.execute("SELECT version();")
        db_version = cursor.fetchone()
        cursor.close()
        connection.close()
        return {
            "status": "Success",
            "message": "Successfully connected to AWS RDS PostgreSQL!",
            "database_version": db_version[0],
        }
    except Exception as e:
        return {
            "status": "Failed",
            "message": "Cannot connect to the database.",
            "error_details": str(e),
        }