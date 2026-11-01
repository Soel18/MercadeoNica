# MercadeoNicaWeb — Guía para levantar el proyecto

Sistema web de ventas e inventario **MercadeoNica** (JSP + Servlets, Jakarta EE 10, Maven, SQL Server). Esta guía contiene cada paso comprobado para compilar y ejecutar la aplicación.

---

## 1. Requisitos previos

| Software | Versión | Comando para verificar |
|---|---|---|
| Java JDK | 17 o superior (probado con Java 21) | `java -version` |
| Maven | 3.8+ | `mvn -version` |
| SQL Server | 2019+ (probado con SQL Server 17) | `ss -tulpn \| grep 1433` |
| Apache Tomcat | 10.1.x (incluido en este proyecto) | — |
| NetBeans (opcional) | con soporte Java EE | — |

> El proyecto ya incluye un **Tomcat 10.1.60 en la carpeta `apache-tomcat-10.1.60/`** del proyecto.

---

## 2. Estructura del proyecto

```
Protecto Final_MercadeoNica/
├── MercadeoNicaWeb_JAVA/
│   └── MercadeoNicaWeb/          ← código de la app
│       ├── pom.xml               ← dependencias (Maven)
│       ├── src/main/java/        ← servlets, DAOs, modelos
│       ├── src/main/webapp/      ← JSPs, CSS, web.xml
│       └── target/               ← WAR generado
├── apache-tomcat-10.1.60/        ← Tomcat del proyecto
├── SQL Server Management Studio 22/
├── Diagrama_ER_OSF.pdf           ← diagrama de la BD
└── Documento Final MercadeoNica.pdf / .docx
```

---

## 3. Base de datos (SQL Server)

La aplicación se conecta a la base de datos **OSF** en SQL Server con estas credenciales (definidas en `MercadeoNicaWeb_JAVA/MercadeoNicaWeb/src/main/java/com/mercadeonica/conexion/ConexionBD.java`):

- Servidor: `localhost` (puerto 1433)
- Base de datos: `OSF`
- Usuario: `sa`
- Contraseña: según la constante `PASSWORD` de `ConexionBD.java`

**Pasos:**

1. Instala y arranca SQL Server (en Linux: `systemctl start mssql-server`).
2. Crea la base de datos `OSF` con el script/backup del proyecto (ver `Diagrama_ER_OSF.pdf`).
3. Verifica que la conexión funciona ejecutando la clase de prueba:
   ```bash
   cd "MercadeoNicaWeb_JAVA/MercadeoNicaWeb"
   mvn dependency:copy-dependencies
   java -cp "target/classes:target/dependency/mssql-jdbc-12.6.1.jre11.jar" com.mercadeonica.conexion.ConexionBD
   ```
   Debe mostrar `✅ Conexión exitosa` (total de clientes, productos, vendedores).

> Si cambias de servidor o credenciales, solo edita las constantes al inicio de `ConexionBD.java` y recompila.

---

## 4. Compilar el WAR (con Maven)

Desde la carpeta del código:

```bash
cd "MercadeoNicaWeb_JAVA/MercadeoNicaWeb"
mvn clean package -DskipTests
```

El resultado queda en `target/MercadeoNicaWeb.war`.

---

## 5. Opción A — Levantar con NetBeans

1. Abre NetBeans → **File → Open Project** y selecciona la carpeta `MercadeoNicaWeb_JAVA/MercadeoNicaWeb`.
2. Clic derecho sobre **MercadeoNicaWeb** → **Clean and Build** (limpiar y compilar).
3. Clic derecho → **Run** (o el ícono ▶).
4. NetBeans arranca el Tomcat y abre el navegador en la raíz del proyecto.

> **Importante:** la página inicial ahora es `login.jsp` (configurado como *welcome-file* en `web.xml`). Si todavía ves la página "¡Hola desde MercadeoNica!" es que estás viendo una versión vieja: vuelve a hacer **Clean and Build** y recarga con **Ctrl+F5**.

---

## 6. Opción B — Levantar sin NetBeans (Tomcat del proyecto)

Usa el Tomcat incluido en la carpeta del proyecto (puerto 8082, ya ajustado para no chocar con otros Tomcat):

```bash
cd "Protecto Final_MercadeoNica/apache-tomcat-10.1.60"
chmod +x bin/*.sh                                  # solo la primera vez
cp ../MercadeoNicaWeb_JAVA/MercadeoNicaWeb/target/MercadeoNicaWeb.war webapps/
export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64   # ruta de tu JDK
bin/startup.sh
```

Detener:

```bash
bin/shutdown.sh
```

---

## 7. Acceso a la aplicación

| URL | Página |
|---|---|
| `http://localhost:8082/MercadeoNicaWeb/` | Login (inicio) |
| `http://localhost:8082/MercadeoNicaWeb/login.jsp` | Login |
| `http://localhost:8082/MercadeoNicaWeb/catalogo-publico.jsp` | Catálogo público |
| `http://localhost:8082/MercadeoNicaWeb/manager/html` | Manager de Tomcat (si está configurado) |

> En NetBeans el puerto suele ser el 8081; en el Tomcat de Ubuntu por defecto es el 8080. El puerto real se ve en la pestaña *Output* de NetBeans o con `ss -tulpn | grep 808`.

**Credenciales de prueba:** ver el archivo `Credenciales del Login.txt` en la raíz del proyecto.

---

## 8. Compartir con clientes (túnel Cloudflare)

Para que terceros accedan a la aplicación mientras corre en tu máquina:

```powershell
# En Windows (PowerShell): instalación y túnel hacia el puerto donde corre Tomcat
winget install --id Cloudflare.cloudflared
cloudflared tunnel --url http://localhost:8081
```

Cloudflare te da una URL pública del estilo:

```
https://xxxx-xxxx-xxxx.trycloudflare.com/MercadeoNicaWeb/login.jsp
```

Esa URL se envía a los clientes. Cambia el puerto por el que le corresponda a tu Tomcat.

---

## 9. Solución de problemas

| Síntoma | Causa y solución |
|---|---|
| Al abrir la raíz sale "¡Hola desde MercadeoNica!" | Falta el welcome-file → en `src/main/webapp/WEB-INF/web.xml` debe existir `<welcome-file-list><welcome-file>login.jsp</welcome-file></welcome-file-list>`. Recompilar. |
| Errores/imports rojos en `MonedaUtil` (PedidoServlet, ClientePedidoServlet) | `MonedaUtil.java` debe vivir en `com/mercadeonica/util/` (paquete `com.mercadeonica.util`), no en `dao/`. |
| `bin/startup.sh: Permiso denegado` | Falta permiso de ejecución → `chmod +x bin/*.sh`. |
| Tomcat no arranca: `java.net.BindException` en puerto 8005/8080 | Ya hay otro Tomcat usando el puerto → cambia los puertos en `conf/server.xml` (HTTP y `Server port` de apagado). |
| `Error de conexión` a la BD | Verifica que SQL Server corra en `localhost:1433`, que la BD `OSF` exista y que las credenciales de `ConexionBD.java` sean correctas. |
| Aviso en el arranque: "APR library version incompatible" | Es inofensivo; Tomcat usa su conector NIO. |
| Aparece la versión vieja tras actualizar | El Tomcat despliega el WAR al arrancar y conserva el `.war` anterior → borra `webapps/MercadeoNicaWeb.war` y `webapps/MercadeoNicaWeb/` antes de copiar el nuevo, o haz **Clean** en NetBeans. |

---

## 10. Notas finales

- Las credenciales de la base de datos están **hardcodeadas** en `ConexionBD.java` — solo para uso académico; en producción deben ir en variables de entorno o un secret manager.
- Archivo "Credenciales del Login.txt" contiene las cuentas de prueba del sistema.
- El `index.jsp` es una página de respaldo de Tomcat; la inicial real es `login.jsp`.
