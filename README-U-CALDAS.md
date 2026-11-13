# Proyecto Yamtrack - Universidad de Caldas

## Ejecución local

### Requisitos

- Docker Desktop instalado y ejecutándose.
- Git instalado.

### Instalación y ejecución

1. Clona el repositorio y entra en su carpeta:

   ```powershell
   git clone https://github.com/FuzzyGrim/Yamtrack.git
   cd Yamtrack
   ```

2. Crea el archivo `.env` a partir de `.env.example`:

   ```powershell
   Copy-Item .env.example .env
   ```

3. Para ejecutar la aplicación localmente con la base de datos SQLite incluida,
   abre `.env` y elimina o comenta las variables `DB_HOST`, `DB_PORT`,
   `DB_NAME`, `DB_USER`, `DB_PASSWORD`, `DB_SSL_MODE` y `DB_SSL_CERT_MODE`.
   Conserva una clave `SECRET` y, si vas a mostrar el dashboard, agrega:

   ```env
   LOOKER_STUDIO_DASHBOARD_URL=https://datastudio.google.com/embed/reporting/ID_DEL_INFORME/page/ID_DE_PAGINA
   ```

4. Inicia la aplicación con Docker Compose:

   ```powershell
   docker compose up -d --build
   ```

5. Comprueba el estado de los servicios:

   ```powershell
   docker compose ps
   ```

6. Abre Yamtrack en el navegador:

   ```text
   http://localhost:8000
   ```

7. Para detener la aplicación sin eliminar los datos:

   ```powershell
   docker compose stop
   ```

8. Para iniciarla nuevamente:

   ```powershell
   docker compose start
   ```