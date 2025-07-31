FROM python:3.11-slim
WORKDIR /app
COPY ./app /app/app
COPY requirements.txt /app/
COPY .env /app/
RUN pip install --no-cache-dir -r requirements.txt
EXPOSE 8000
HEALTHCHECK --interval=30s --timeout=3s CMD curl -f http://localhost:8000/health || exit 1
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000", "--workers", "4"]
