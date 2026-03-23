FROM python:3.12-alpine
WORKDIR /app
COPY server.py .
ENV PORT=8080
ENV APP_VERSION=1.0.0
ENV APP_ENV=kubernetes
EXPOSE 8080
CMD ["python3", "server.py"]
