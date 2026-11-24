FROM python:3.13-slim
WORKDIR /app

# 1. Copiar o ficheiro de dependencias
COPY requirements.txt .

# 2. Instalar as dependencias
RUN pip install --no-cache-dir -r requirements.txt

# 3. Copiar a aplicacao
COPY app.py .

# 4. Criar utilizador sem privilegios e preparar /data
RUN useradd --create-home appuser \
    && mkdir -p /data \
    && chown appuser:appuser /data

# 5. Executar com utilizador nao privilegiado
USER appuser

EXPOSE 8000
CMD ["python", "-m", "uvicorn", "app:app", "--host", "0.0.0.0", "--port", "8000"]
