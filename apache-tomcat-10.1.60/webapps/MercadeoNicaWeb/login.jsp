<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Iniciar Sesión - MercadeoNica</title>
    <link rel="stylesheet" href="css/estilos.css">
</head>
<body>

    <div class="login-container">
        <h1>🛒 MercadeoNica</h1>
        <h2>Iniciar sesión</h2>

        <%-- Mensaje de error --%>
        <% String error = (String) request.getAttribute("error"); %>
        <% if (error != null) { %>
            <div class="error">⚠️ <%= error %></div>
        <% } %>

        <%-- Mensaje de éxito (ej: registro exitoso) --%>
        <% String mensaje = (String) request.getAttribute("mensaje"); %>
        <% if (mensaje != null) { %>
            <div class="ok">✅ <%= mensaje %></div>
        <% } %>

        <form action="LoginUnificadoServlet" method="post">

            <label for="email">Correo electrónico:</label>
            <input type="email"
                   id="email"
                   name="email"
                   placeholder="tu@correo.com"
                   required
                   autofocus>

            <label for="password">Contraseña:</label>
            <input type="password"
                   id="password"
                   name="password"
                   placeholder="Tu contraseña"
                   required>

            <button type="submit">Iniciar sesión</button>
        </form>

        <p class="hint" style="margin-top: 25px;">
            ¿No tienes cuenta? <a href="cliente-registro.jsp"><b>Regístrate aquí</b></a>
        </p>

        <p class="hint" style="color: #95a5a6; font-size: 0.78em; margin-top: 15px;">
            ℹ️ El sistema detecta automáticamente si eres administrador, vendedor o cliente.
        </p>
    </div>

</body>
</html>