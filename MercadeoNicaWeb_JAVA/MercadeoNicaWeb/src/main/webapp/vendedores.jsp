<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.util.List" %>
<%@ page import="com.mercadeonica.modelo.Vendedor" %>
<%
    Vendedor admin = (Vendedor) session.getAttribute("vendedor");
    if (admin == null) {
        response.sendRedirect("login.jsp");
        return;
    }

    if (!admin.esAdmin()) {
        response.sendRedirect("menu.jsp");
        return;
    }

    List<Vendedor> vendedores = (List<Vendedor>) request.getAttribute("vendedores");
    Vendedor vendedorSeleccionado = (Vendedor) request.getAttribute("vendedorSeleccionado");
    Vendedor vendedorEditar       = (Vendedor) request.getAttribute("vendedorEditar");
    String mensaje = (String) request.getAttribute("mensaje");
    
    String editNombre  = (String) request.getAttribute("editNombre");
    String editApellido= (String) request.getAttribute("editApellido");
    if (editNombre == null) editNombre = "";
    if (editApellido == null) editApellido = "";
%>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <title>Vendedores - MercadeoNica</title>
    <link rel="stylesheet" href="css/estilos.css">
</head>
<body>

    <header>
        <h1>🛒 MercadeoNica</h1>
                <nav>
            <a href="menu.jsp">Inicio</a>
            <a href="DashboardServlet">Dashboard</a>
            <a href="ProductoServlet">Productos</a>
            <a href="ClienteServlet">Clientes</a>
            <a href="carrito.jsp">Carrito</a>
            <a href="PedidoServlet">Pedidos</a>
            <a href="ReporteServlet">Reportes</a>
            <a href="VendedorServlet"><b>👔 Vendedores</b></a>
        </nav>
        <div class="user-info">
            <span>👤 <%= admin.getNombre() %></span>
            <span class="badge" style="background-color: #e74c3c;"><%= admin.getRol() %></span>
            <a href="LogoutServlet" class="logout">Salir</a>
        </div>
    </header>

    <main>
        <% if (mensaje != null) { 
            boolean esError = mensaje.toLowerCase().contains("error") || 
                              mensaje.toLowerCase().contains("❌") || 
                              mensaje.toLowerCase().contains("no se pudo") ||
                              mensaje.toLowerCase().contains("inválido");
            String bgColor = esError ? "#fdecea" : "#eafaf1";
            String textColor = esError ? "#c0392b" : "#27ae60";
            String borderColor = esError ? "#c0392b" : "#27ae60";
            String icono = esError ? "❌" : "✅";
        %>
            <div style="background-color: <%= bgColor %>; color: <%= textColor %>; padding: 12px; border-radius: 6px; margin-bottom: 20px; border-left: 4px solid <%= borderColor %>; font-weight: bold;">
                <%= icono %> <%= mensaje %>
            </div>
        <% } %>

        <h2>👔 Gestión de Vendedores (Trabajadores)</h2>
        <p style="color: #7f8c8d; margin-bottom: 20px;">
            Agrega, edita, elimina o cambia la contraseña de tus vendedores.
        </p>

        <div class="tabla-scroll">
            <table>
                <thead>
                    <tr>
                        <th>ID</th>
                        <th>Nombre Completo</th>
                        <th>Email</th>
                        <th>📱 Teléfono</th>
                        <th>Rol</th>
                        <th>Estado</th>
                        <th>Acciones</th>
                    </tr>
                </thead>
                <tbody>
                    <% if (vendedores != null) for (Vendedor v : vendedores) { %>
                        <tr>
                            <td><%= v.getSellerId() %></td>
                            <td><b><%= v.getNombre() %></b></td>
                            <td><%= v.getEmail() %></td>
                            <td>
                                <% if (v.getTelefono() != null && !v.getTelefono().isEmpty()) { %>
                                    <span style="white-space: nowrap;">📞 <%= v.getTelefono() %></span>
                                <% } else { %>
                                    <span style="color: #999;">—</span>
                                <% } %>
                            </td>
                            <td>
                                <span class="badge" style="background-color: <%= v.esAdmin() ? "#e74c3c" : "#3498db" %>;">
                                    <%= v.getRol() %>
                                </span>
                            </td>
                            <td>
                                <% if (v.isActivo()) { %>
                                    <span style="color: #27ae60;">✅ Activo</span>
                                <% } else { %>
                                    <span style="color: #c0392b;">❌ Inactivo</span>
                                <% } %>
                            </td>
                            <td>
                                <% if (v.getSellerId() == admin.getSellerId()) { %>
                                    <div style="display: flex; gap: 5px; align-items: center;">
                                        <a href="VendedorServlet?accion=editar&id=<%= v.getSellerId() %>"
                                           class="btn"
                                           style="background-color: #3498db; white-space: nowrap; padding: 6px 12px; font-size: 0.85em;">
                                           ✏️ Editar mis datos
                                        </a>
                                        <span style="color: #999; font-size: 0.85em; font-style: italic;">Tú</span>
                                    </div>
                                <% } else { %>
                                    <div style="display: flex; gap: 5px; align-items: center; flex-wrap: nowrap;">
                                        <a href="VendedorServlet?accion=editar&id=<%= v.getSellerId() %>"
                                           class="btn"
                                           style="background-color: #3498db; white-space: nowrap; padding: 6px 12px; font-size: 0.85em;">
                                           ✏️ Editar
                                        </a>

                                        <a href="VendedorServlet?accion=eliminar&id=<%= v.getSellerId() %>"
                                           class="btn-eliminar"
                                           style="white-space: nowrap; padding: 6px 12px; font-size: 0.85em;"
                                           onclick="return confirm('¿Eliminar este vendedor?')">
                                           Eliminar
                                        </a>

                                        <% if (v.isActivo()) { %>
                                            <a href="VendedorServlet?accion=desactivar&id=<%= v.getSellerId() %>"
                                               class="btn"
                                               style="background-color: #f39c12; white-space: nowrap; padding: 6px 12px; font-size: 0.85em;"
                                               onclick="return confirm('¿Desactivar este vendedor?')">
                                               Desactivar
                                            </a>
                                        <% } else { %>
                                            <a href="VendedorServlet?accion=activar&id=<%= v.getSellerId() %>"
                                               class="btn"
                                               style="background-color: #27ae60; white-space: nowrap; padding: 6px 12px; font-size: 0.85em;"
                                               onclick="return confirm('¿Activar este vendedor?')">
                                               Activar
                                            </a>
                                        <% } %>

                                        <a href="VendedorServlet?accion=formPassword&id=<%= v.getSellerId() %>"
                                           class="btn"
                                           style="background-color: #9b59b6; white-space: nowrap; padding: 6px 12px; font-size: 0.85em;">
                                           🔐 Contraseña
                                        </a>
                                    </div>
                                <% } %>
                            </td>
                        </tr>
                    <% } %>
                </tbody>
            </table>
        </div>

        <% if (vendedorEditar != null) { %>
            <div class="form-container" style="border: 3px solid #3498db; background: #eaf4fc; margin-top: 30px;">
                <h2 style="color: #2980b9; margin-top: 0;">
                    ✏️ Editar Vendedor #<%= vendedorEditar.getSellerId() %>
                </h2>

                <div style="background: #f8f9fa; padding: 15px; border-radius: 8px; margin-bottom: 20px;">
                    <p style="margin: 0;"><b>Email actual:</b> <%= vendedorEditar.getEmail() %></p>
                    <p style="margin: 5px 0 0 0;"><b>Rol actual:</b> 
                        <span class="badge" style="background-color: <%= vendedorEditar.esAdmin() ? "#e74c3c" : "#3498db" %>;">
                            <%= vendedorEditar.getRol() %>
                        </span>
                    </p>
                </div>

                <form action="VendedorServlet" method="post">
                    <input type="hidden" name="accion" value="guardarEdicion">
                    <input type="hidden" name="sellerId" value="<%= vendedorEditar.getSellerId() %>">
                    <input type="hidden" name="rolOriginal" value="<%= vendedorEditar.getRol() %>">

                    <div style="display: flex; gap: 10px;">
                        <div class="form-group" style="flex: 1;">
                            <label>Nombre:</label>
                            <input type="text" name="nombre" required value="<%= editNombre %>">
                        </div>
                        <div class="form-group" style="flex: 1;">
                            <label>Apellido:</label>
                            <input type="text" name="apellido" required value="<%= editApellido %>">
                        </div>
                    </div>

                    <div class="form-group">
                        <label>Correo electrónico:</label>
                        <input type="email" name="email" required
                               value="<%= vendedorEditar.getEmail() != null ? vendedorEditar.getEmail() : "" %>">
                    </div>

                    <div class="form-group">
                        <label>Teléfono (opcional):</label>
                        <input type="tel" name="telefono"
                               pattern="[+]?[\d\s\-()]{7,20}"
                               placeholder="Ej: +505 8888-8888"
                               value="<%= vendedorEditar.getTelefono() != null ? vendedorEditar.getTelefono() : "" %>">
                    </div>

                    <div class="form-group">
                        <label>Rol:</label>
                        <select name="rol" required
                                <%= (vendedorEditar.getSellerId() == admin.getSellerId()) ? "disabled" : "" %>>
                            <option value="VENDEDOR" <%= "VENDEDOR".equals(vendedorEditar.getRol()) ? "selected" : "" %>>
                                VENDEDOR (Trabajador)
                            </option>
                            <option value="ADMIN" <%= "ADMIN".equals(vendedorEditar.getRol()) ? "selected" : "" %>>
                                ADMIN (Administrador)
                            </option>
                        </select>

                        <% if (vendedorEditar.getSellerId() == admin.getSellerId()) { %>
                            <input type="hidden" name="rol" value="<%= vendedorEditar.getRol() %>">
                            <p style="color: #e67e22; font-size: 0.85em; margin-top: 5px;">
                                🔒 No puedes cambiar tu propio rol (evita bloquearte).
                            </p>
                        <% } %>
                    </div>

                    <div style="display: flex; gap: 10px; margin-top: 20px;">
                        <button type="submit" class="btn-primary" style="background-color: #2980b9;">
                            💾 Guardar cambios
                        </button>
                        <a href="VendedorServlet" class="btn" style="background-color: #95a5a6;">
                            Cancelar
                        </a>
                    </div>
                </form>
            </div>
        <% } %>

        <% if (vendedorSeleccionado != null) { %>
            <div class="form-container" style="border: 3px solid #9b59b6; margin-top: 30px;">
                <h2 style="color: #9b59b6;">🔐 Cambiar Contraseña</h2>

                <div style="background: #f8f9fa; padding: 15px; border-radius: 8px; margin-bottom: 20px;">
                    <p><b>Vendedor:</b> <%= vendedorSeleccionado.getNombre() %></p>
                    <p><b>Email:</b> <%= vendedorSeleccionado.getEmail() %></p>
                    <p><b>Rol:</b> <%= vendedorSeleccionado.getRol() %></p>
                </div>

                <form action="VendedorServlet" method="post">
                    <input type="hidden" name="accion" value="cambiarPassword">
                    <input type="hidden" name="sellerId" value="<%= vendedorSeleccionado.getSellerId() %>">

                    <div class="form-group">
                        <label>Nueva contraseña:</label>
                        <input type="text" name="passwordNueva" required minlength="6"
                               placeholder="Mínimo 6 caracteres">
                    </div>

                    <div class="form-group">
                        <label>Confirmar nueva contraseña:</label>
                        <input type="text" name="passwordConfirm" required minlength="6"
                               placeholder="Repite la nueva contraseña">
                    </div>

                    <div style="display: flex; gap: 10px; margin-top: 20px;">
                        <button type="submit" class="btn-primary" style="background-color: #9b59b6;">
                            🔐 Cambiar contraseña
                        </button>
                        <a href="VendedorServlet" class="btn">Cancelar</a>
                    </div>
                </form>
            </div>
        <% } %>

        <h2>➕ Agregar nuevo vendedor</h2>
        <div class="form-container">
            <form action="VendedorServlet" method="post">
                <div style="display: flex; gap: 10px;">
                    <div class="form-group" style="flex: 1;">
                        <label>Nombre:</label>
                        <input type="text" name="nombre" required>
                    </div>
                    <div class="form-group" style="flex: 1;">
                        <label>Apellido:</label>
                        <input type="text" name="apellido" required>
                    </div>
                </div>

                <div class="form-group">
                    <label>Correo electrónico:</label>
                    <input type="email" name="email" required>
                </div>

                <div class="form-group">
                    <label>Teléfono (opcional):</label>
                    <input type="tel"
                           name="telefono"
                           pattern="[+]?[\d\s\-()]{7,20}"
                           placeholder="Ej: +505 8888-8888"
                           title="Formato: +505 8888-8888">
                </div>

                <div class="form-group">
                    <label>Contraseña:</label>
                    <input type="text" name="password" required minlength="6"
                           placeholder="Mínimo 6 caracteres">
                </div>

                <div class="form-group">
                    <label>Rol:</label>
                    <select name="rol" required>
                        <option value="VENDEDOR">VENDEDOR (Trabajador)</option>
                        <option value="ADMIN">ADMIN (Administrador)</option>
                    </select>
                </div>

                <button type="submit" class="btn-primary">Agregar vendedor</button>
            </form>
        </div>
    </main>

</body>
</html>