<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <title>MercadeoNica - Inicio</title>
    <style>
        body {
            font-family: 'Segoe UI', Arial, sans-serif;
            background: #f4f6f8;
            padding: 40px;
            text-align: center;
        }
        .container {
            max-width: 600px;
            margin: 0 auto;
            background: white;
            padding: 30px;
            border-radius: 10px;
            box-shadow: 0 4px 12px rgba(0,0,0,0.1);
        }
        h1 {
            color: #2c3e50;
        }
        p {
            color: #7f8c8d;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>¡Hola desde MercadeoNica!</h1>
        <p>Si ves esta página, Tomcat está desplegando el proyecto correctamente.</p>
        <p>Fecha actual: <%= new java.util.Date() %></p>
    </div>
</body>
</html>