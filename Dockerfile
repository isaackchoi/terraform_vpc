FROM python:3.9-slim

WORKDIR /app

# 💡 關鍵步驟：先把依賴清單複製進去，並用 pip 安裝好套件
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# 💡 接著把我們剛寫好的 app.py 複製進去
COPY app.py .

EXPOSE 80

CMD ["uvicorn", "app:app", "--host", "0.0.0.0", "--port", "80"]