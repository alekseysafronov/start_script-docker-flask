#!/bin/bash

# Создаем структуру проекта
mkdir -p flask-react-docker/{backend,frontend}

# Переходим в директорию проекта
cd flask-react-docker

# Создаем docker-compose.yml
cat <<EOF > docker-compose.yml
version: '3.8'

services:
  backend:
    build: ./backend
    ports:
      - "5000:5000"
    environment:
      - FLASK_ENV=development
    volumes:
      - ./backend:/app
    networks:
      - app-network

  frontend:
    build: ./frontend
    ports:
      - "3000:3000"
    volumes:
      - ./frontend:/app
      - /app/node_modules
    environment:
      - NODE_ENV=development
    stdin_open: true
    tty: true
    networks:
      - app-network
    depends_on:
      - backend

  db:
    image: postgres:13
    environment:
      - POSTGRES_USER=postgres
      - POSTGRES_PASSWORD=postgres
      - POSTGRES_DB=flaskdb
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data
    networks:
      - app-network

volumes:
  postgres_data:

networks:
  app-network:
    driver: bridge
EOF

# Создаем backend/Dockerfile
cat <<EOF > backend/Dockerfile
FROM python:3.9-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

CMD ["flask", "run", "--host", "0.0.0.0"]
EOF

# Создаем backend/requirements.txt
cat <<EOF > backend/requirements.txt
flask
flask-sqlalchemy
psycopg2-binary
EOF

# Создаем простой Flask app
cat <<EOF > backend/app.py
from flask import Flask, jsonify

app = Flask(__name__)

@app.route('/api/hello')
def hello():
    return jsonify(message="Hello from Flask!")

if __name__ == '__main__':
    app.run(debug=True)
EOF

# Создаем frontend/Dockerfile
cat <<EOF > frontend/Dockerfile
FROM node:16

WORKDIR /app

COPY package*.json ./

RUN npm install

COPY . .

EXPOSE 3000

CMD ["npm", "start"]
EOF

# Инициализируем React-приложение
npx create-react-app frontend

# Настраиваем proxy для React
cat <<EOF > frontend/package.json
{
  "name": "frontend",
  "version": "0.1.0",
  "private": true,
  "dependencies": {
    "@testing-library/jest-dom": "^5.17.0",
    "@testing-library/react": "^13.4.0",
    "@testing-library/user-event": "^13.5.0",
    "react": "^18.2.0",
    "react-dom": "^18.2.0",
    "react-scripts": "5.0.1",
    "web-vitals": "^2.1.4"
  },
  "scripts": {
    "start": "react-scripts start",
    "build": "react-scripts build",
    "test": "react-scripts test",
    "eject": "react-scripts eject"
  },
  "eslintConfig": {
    "extends": [
      "react-app",
      "react-app/jest"
    ]
  },
  "browserslist": {
    "production": [
      ">0.2%",
      "not dead",
      "not op_mini all"
    ],
    "development": [
      "last 1 chrome version",
      "last 1 firefox version",
      "last 1 safari version"
    ]
  },
  "proxy": "http://backend:5000"
}
EOF

# Добавляем пример компонента для проверки связи с бэкендом
cat <<EOF > frontend/src/App.js
import { useEffect, useState } from 'react';
import './App.css';

function App() {
  const [message, setMessage] = useState('');

  useEffect(() => {
    fetch('/api/hello')
      .then(res => res.json())
      .then(data => setMessage(data.message))
      .catch(err => console.error(err));
  }, []);

  return (
    <div className="App">
      <header className="App-header">
        <h1>React + Flask Docker App</h1>
        <p>Backend response: {message}</p>
      </header>
    </div>
  );
}

export default App;
EOF

# Запускаем приложение
docker-compose up --build
