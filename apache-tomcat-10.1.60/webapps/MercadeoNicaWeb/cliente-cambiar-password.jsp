<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="com.mercadeonica.modelo.Cliente" %>
<%
    Cliente cliente = (Cliente) session.getAttribute("cliente");
    if (cliente == null) {
        response.sendRedirect("login.jsp");
        return;
    }
    // Si ya cambió la contraseña, no tiene por qué estar aquí
    if (!cliente.isDebeCambiarPassword()) {
        response.sendRedirect("cliente-menu.jsp");
        return;
    }
%>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <title>Cambiar Contraseña - MercadeoNica</title>
    <link rel="stylesheet" href="css/estilos.css">
</head>
<body>
    <div class="login-container" style="max-width: 500px; margin-top: 60px;">
        <h1>🛒 MercadeoNica</h1>
        <h2 style="color: #e67e22;">🔐 Acción Requerida</h2>
        
        <div class="welcome-card" style="background:#fef9e7; border-left:4px solid #f39c12; padding:15px; margin-bottom:20px;">
            <p style="color:#b9770e; margin:0;">
                <b>¡Hola, <%= cliente.getNombre() %>!</b><br>
                Un administrador o vendedor creó tu cuenta. Por seguridad, <b>debes cambiar tu contraseña provisional</b> antes de continuar.
            </p>
        </div>

        <% String error = (String) request.getAttribute("error"); %>
        <% if (error != null) { %>
            <div class="error">⚠️ <%= error %></div>
        <% } %>

        <form action="CambiarPasswordServlet" method="post">
            <label>Nueva Contraseña:</label>
            <input type="password" name="nuevaPassword" required minlength="6" placeholder="Mínimo 6 caracteres">

            <label>Confirmar Nueva Contraseña:</label>
            <input type="password" name="confirmarPassword" required minlength="6" placeholder="Repite la contraseña">

            <button type="submit" style="background-color: #e67e22;">Guardar y Continuar</button>
        </form>
    </div>
</body>
</html>