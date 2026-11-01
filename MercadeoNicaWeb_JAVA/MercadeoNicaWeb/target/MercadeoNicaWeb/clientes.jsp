<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.util.List" %>
<%@ page import="com.mercadeonica.modelo.Cliente" %>
<%@ page import="com.mercadeonica.modelo.CategoriaCliente" %>
<%@ page import="com.mercadeonica.modelo.Vendedor" %>
<%
    response.setHeader("Cache-Control", "no-cache, no-store, must-revalidate");
    response.setHeader("Pragma", "no-cache");
    response.setDateHeader("Expires", 0);
%>
<%
    Vendedor vendedor = (Vendedor) session.getAttribute("vendedor");
    if (vendedor == null) {
        response.sendRedirect("login.jsp");
        return;
    }

    List<Cliente> clientes = (List<Cliente>) request.getAttribute("clientes");
    List<CategoriaCliente> categoriasCliente = (List<CategoriaCliente>) request.getAttribute("categoriasCliente");
    Cliente clienteEditar = (Cliente) request.getAttribute("clienteEditar");
    String mensaje = (String) request.getAttribute("mensaje");
    boolean esAdmin = vendedor.esAdmin();
    
    String filtroQ = (String) request.getAttribute("filtroQ");
    if (filtroQ == null) filtroQ = "";

    String regNombre   = (String) request.getAttribute("reg_nombre");
    String regApellido = (String) request.getAttribute("reg_apellido");
    String regEmail    = (String) request.getAttribute("reg_email");
    String regCiudad   = (String) request.getAttribute("reg_ciudad");
    String regEstado   = (String) request.getAttribute("reg_estado");
    String regZip      = (String) request.getAttribute("reg_zip");
    String regTelefono = (String) request.getAttribute("reg_telefono");
    String regPassword = (String) request.getAttribute("reg_password");
    String regTarjeta  = (String) request.getAttribute("reg_tarjeta");
    String regTipo     = (String) request.getAttribute("reg_tipo");
    String regMes      = (String) request.getAttribute("reg_mes");
    String regAnio     = (String) request.getAttribute("reg_anio");
    String errorField  = (String) request.getAttribute("error_field");
    String editNombre  = (String) request.getAttribute("editNombre");
    String editApellido= (String) request.getAttribute("editApellido");
    
    if (regNombre == null) regNombre = "";
    if (regApellido == null) regApellido = "";
    if (regEmail == null) regEmail = "";
    if (regCiudad == null) regCiudad = "";
    if (regEstado == null) regEstado = "";
    if (regZip == null) regZip = "";
    if (regTelefono == null) regTelefono = "";
    if (regPassword == null) regPassword = "";
    if (regTarjeta == null) regTarjeta = "";
    if (regTipo == null) regTipo = "";
    if (regMes == null) regMes = "";
    if (regAnio == null) regAnio = "";
    if (editNombre == null) editNombre = "";
    if (editApellido == null) editApellido = "";

    String styleNombre  = "nombre".equals(errorField) ? "border: 2px solid #e74c3c; background-color: #fdecea;" : "";
    String styleEmail   = "email".equals(errorField) ? "border: 2px solid #e74c3c; background-color: #fdecea; box-shadow: 0 0 8px rgba(231, 76, 60, 0.6);" : "";
    String styleTel     = "telefono".equals(errorField) ? "border: 2px solid #e74c3c; background-color: #fdecea;" : "";
    String styleTarjeta = "tarjeta".equals(errorField) ? "border: 2px solid #e74c3c; background-color: #fdecea;" : "";
%>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <title>Clientes - MercadeoNica</title>
    <link rel="stylesheet" href="css/estilos.css">
    <script>
        // 🔥 MAPA DE CIUDADES POR PAÍS
        const ciudadesPorPais = {
            "Nicaragua": ["Managua", "León", "Granada", "Masaya", "Matagalpa", "Estelí", "Chinandega", "Jinotega", "Rivas", "Carazo", "Boaco", "Chontales", "Río San Juan", "RACCN", "RACCS"],
            "Costa Rica": ["San José", "Alajuela", "Cartago", "Heredia", "Liberia", "Puntarenas", "Limón"],
            "Honduras": ["Tegucigalpa", "San Pedro Sula", "La Ceiba", "Choloma", "El Progreso"],
            "El Salvador": ["San Salvador", "Santa Ana", "San Miguel", "Soyapango", "Mejicanos"],
            "Guatemala": ["Ciudad de Guatemala", "Quetzaltenango", "Escuintla", "Mixco", "Antigua Guatemala"],
            "Panamá": ["Ciudad de Panamá", "Colón", "David", "La Chorrera", "Santiago"],
            "Estados Unidos": ["Nueva York", "Los Ángeles", "Chicago", "Houston", "Miami", "Washington D.C.", "Boston", "Seattle", "San Francisco", "Atlanta"],
            "México": ["Ciudad de México", "Guadalajara", "Monterrey", "Puebla", "Tijuana", "Cancún", "Mérida"],
            "Colombia": ["Bogotá", "Medellín", "Cali", "Barranquilla", "Cartagena", "Bucaramanga"],
            "Venezuela": ["Caracas", "Maracaibo", "Valencia", "Barquisimeto", "Maracay"],
            "Ecuador": ["Quito", "Guayaquil", "Cuenca", "Santo Domingo", "Machala"],
            "Perú": ["Lima", "Arequipa", "Trujillo", "Chiclayo", "Piura"],
            "Bolivia": ["La Paz", "Santa Cruz de la Sierra", "Cochabamba", "Sucre", "Oruro"],
            "Chile": ["Santiago", "Valparaíso", "Concepción", "Antofagasta", "Viña del Mar"],
            "Argentina": ["Buenos Aires", "Córdoba", "Rosario", "Mendoza", "La Plata"],
            "Brasil": ["São Paulo", "Río de Janeiro", "Brasilia", "Salvador", "Fortaleza"],
            "Uruguay": ["Montevideo", "Salto", "Ciudad de la Costa", "Paysandú"],
            "Paraguay": ["Asunción", "Ciudad del Este", "San Lorenzo", "Luque"],
            "Cuba": ["La Habana", "Santiago de Cuba", "Camagüey", "Holguín"],
            "República Dominicana": ["Santo Domingo", "Santiago de los Caballeros", "La Romana", "San Pedro de Macorís"],
            "Puerto Rico": ["San Juan", "Bayamón", "Carolina", "Ponce"],
            "España": ["Madrid", "Barcelona", "Valencia", "Sevilla", "Zaragoza", "Málaga", "Bilbao"],
            "Francia": ["París", "Marsella", "Lyon", "Toulouse", "Niza"],
            "Alemania": ["Berlín", "Hamburgo", "Múnich", "Colonia", "Frankfurt"],
            "Italia": ["Roma", "Milán", "Nápoles", "Turín", "Florencia"],
            "Reino Unido": ["Londres", "Manchester", "Birmingham", "Liverpool", "Edimburgo"],
            "Portugal": ["Lisboa", "Oporto", "Braga", "Coímbra"],
            "Países Bajos": ["Ámsterdam", "Róterdam", "La Haya", "Utrecht"],
            "Bélgica": ["Bruselas", "Amberes", "Gante", "Lieja"],
            "Suiza": ["Zúrich", "Ginebra", "Berna", "Basilea"],
            "Suecia": ["Estocolmo", "Gotemburgo", "Malmö", "Upsala"],
            "Noruega": ["Oslo", "Bergen", "Trondheim", "Stavanger"],
            "Dinamarca": ["Copenhague", "Aarhus", "Odense", "Aalborg"],
            "Rusia": ["Moscú", "San Petersburgo", "Novosibirsk", "Ekaterimburgo"],
            "Ucrania": ["Kiev", "Járkov", "Odesa", "Dnipró"],
            "Polonia": ["Varsovia", "Cracovia", "Gdansk", "Łódź"],
            "Grecia": ["Atenas", "Tesalónica", "Patras", "Heraclión"],
            "Irlanda": ["Dublín", "Cork", "Galway", "Limerick"],
            "Austria": ["Viena", "Graz", "Linz", "Salzburgo"],
            "China": ["Pekín", "Shanghái", "Cantón", "Shenzhen", "Chengdu"],
            "Japón": ["Tokio", "Osaka", "Kioto", "Nagoya", "Sapporo"],
            "Corea del Sur": ["Seúl", "Busan", "Incheon", "Daegu"],
            "India": ["Nueva Delhi", "Bombay", "Bangalore", "Chennai", "Kolkata"],
            "Indonesia": ["Yakarta", "Surabaya", "Bandung", "Medan"],
            "Filipinas": ["Manila", "Quezón", "Dávao", "Cebú"],
            "Tailandia": ["Bangkok", "Chiang Mai", "Phuket", "Pattaya"],
            "Vietnam": ["Hanói", "Ciudad Ho Chi Minh", "Da Nang", "Hai Phong"],
            "Malasia": ["Kuala Lumpur", "Penang", "Johor Bahru", "Ipoh"],
            "Singapur": ["Singapur"],
            "Egipto": ["El Cairo", "Alejandría", "Giza", "Luxor"],
            "Sudáfrica": ["Johannesburgo", "Ciudad del Cabo", "Durban", "Pretoria"],
            "Nigeria": ["Lagos", "Abuya", "Kano", "Ibadan"],
            "Kenia": ["Nairobi", "Mombasa", "Kisumu", "Nakuru"],
            "Marruecos": ["Casablanca", "Rabat", "Marrakech", "Fez"],
            "Argelia": ["Argel", "Orán", "Constantina", "Annaba"],
            "Australia": ["Sídney", "Melbourne", "Brisbane", "Perth", "Adelaida"],
            "Nueva Zelanda": ["Auckland", "Wellington", "Christchurch", "Hamilton"]
        };

        // 🔥 ACTUALIZAR CIUDADES CUANDO CAMBIA EL PAÍS
        function actualizarCiudades(selectPais, selectCiudad) {
            const pais = selectPais.value;
            selectCiudad.innerHTML = '<option value="">-- Selecciona una ciudad --</option>';
            
            if (ciudadesPorPais[pais]) {
                ciudadesPorPais[pais].forEach(ciudad => {
                    const option = document.createElement("option");
                    option.value = ciudad;
                    option.textContent = ciudad;
                    selectCiudad.appendChild(option);
                });
                selectCiudad.disabled = false;
            } else {
                const option = document.createElement("option");
                option.value = "";
                option.textContent = "No hay ciudades predefinidas para este país";
                selectCiudad.appendChild(option);
                selectCiudad.disabled = true;
            }
        }
    </script>
</head>
<body>

    <header>
        <h1>🛒 MercadeoNica</h1>
        <nav>
            <a href="menu.jsp">Inicio</a>
            <% if (esAdmin) { %>
                <a href="DashboardServlet">Dashboard</a>
            <% } %>
            <a href="ProductoServlet">Productos</a>
            <a href="ClienteServlet"><b>Clientes</b></a>
            <a href="carrito.jsp">Carrito</a>
            <a href="PedidoServlet">Pedidos</a>
            <% if (esAdmin) { %>
                <a href="ReporteServlet">Reportes</a>
                <a href="VendedorServlet">Vendedores</a>
            <% } %>
        </nav>
        <div class="user-info">
            <span>👤 <%= vendedor.getNombre() %></span>
            <span class="badge" style="background-color: <%= esAdmin ? "#e74c3c" : "#3498db" %>;">
                <%= vendedor.getRol() %>
            </span>
            <a href="LogoutServlet" class="logout">Salir</a>
        </div>
    </header>

    <main>
        <% if (mensaje != null) { %>
            <div style="background-color: <%= errorField != null ? "#fdecea" : "#eafaf1" %>; 
                        color: <%= errorField != null ? "#c0392b" : "#27ae60" %>; 
                        padding: 12px; border-radius: 6px; margin-bottom: 20px; 
                        border-left: 4px solid <%= errorField != null ? "#c0392b" : "#27ae60" %>; 
                        font-weight: bold;">
                <%= mensaje %>
            </div>
        <% } %>

        <% if (clienteEditar != null) { %>
            <div class="form-container" style="border: 3px solid #3498db; background: #eaf4fc; margin-bottom: 25px;">
                <h2 style="color: #2980b9; margin-top: 0;">✏️ Editar Cliente #<%= clienteEditar.getCustomerId() %></h2>
                <p style="color: #7f8c8d; margin-bottom: 15px;">Modifica los datos y presiona <b>Guardar cambios</b>.</p>

                <form action="ClienteServlet" method="post">
                    <input type="hidden" name="accion" value="guardarEdicion">
                    <input type="hidden" name="customerId" value="<%= clienteEditar.getCustomerId() %>">

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
                        <input type="email" name="email" required value="<%= clienteEditar.getEmail() != null ? clienteEditar.getEmail() : "" %>">
                    </div>
                    <div class="form-group">
                        <label>Teléfono (opcional):</label>
                        <input type="tel" name="telefono" pattern="^\+505[\s\-]?[0-9\s\-]{8,15}$" title="Debe empezar con +505" placeholder="Ej: +505 8888-8888" value="<%= clienteEditar.getTelefono() != null ? clienteEditar.getTelefono() : "" %>">
                    </div>
                    
                    <!-- 🔥 PRIMERO: PAÍS -->
                    <div class="form-group">
                        <label>País:</label>
                        <select name="estado" id="paisEditar" required onchange="actualizarCiudades(this, document.getElementById('ciudadEditar'))">
                            <option value="">-- Selecciona un país --</option>
                            <optgroup label="🌎 América">
                                <option value="Argentina" <%= "Argentina".equals(clienteEditar.getEstado()) ? "selected" : "" %>>Argentina</option>
                                <option value="Bolivia" <%= "Bolivia".equals(clienteEditar.getEstado()) ? "selected" : "" %>>Bolivia</option>
                                <option value="Brasil" <%= "Brasil".equals(clienteEditar.getEstado()) ? "selected" : "" %>>Brasil</option>
                                <option value="Canadá" <%= "Canadá".equals(clienteEditar.getEstado()) ? "selected" : "" %>>Canadá</option>
                                <option value="Chile" <%= "Chile".equals(clienteEditar.getEstado()) ? "selected" : "" %>>Chile</option>
                                <option value="Colombia" <%= "Colombia".equals(clienteEditar.getEstado()) ? "selected" : "" %>>Colombia</option>
                                <option value="Costa Rica" <%= "Costa Rica".equals(clienteEditar.getEstado()) ? "selected" : "" %>>Costa Rica</option>
                                <option value="Cuba" <%= "Cuba".equals(clienteEditar.getEstado()) ? "selected" : "" %>>Cuba</option>
                                <option value="Ecuador" <%= "Ecuador".equals(clienteEditar.getEstado()) ? "selected" : "" %>>Ecuador</option>
                                <option value="El Salvador" <%= "El Salvador".equals(clienteEditar.getEstado()) ? "selected" : "" %>>El Salvador</option>
                                <option value="Estados Unidos" <%= "Estados Unidos".equals(clienteEditar.getEstado()) ? "selected" : "" %>>Estados Unidos</option>
                                <option value="Guatemala" <%= "Guatemala".equals(clienteEditar.getEstado()) ? "selected" : "" %>>Guatemala</option>
                                <option value="Honduras" <%= "Honduras".equals(clienteEditar.getEstado()) ? "selected" : "" %>>Honduras</option>
                                <option value="México" <%= "México".equals(clienteEditar.getEstado()) ? "selected" : "" %>>México</option>
                                <option value="Nicaragua" <%= "Nicaragua".equals(clienteEditar.getEstado()) ? "selected" : "" %>>Nicaragua</option>
                                <option value="Panamá" <%= "Panamá".equals(clienteEditar.getEstado()) ? "selected" : "" %>>Panamá</option>
                                <option value="Paraguay" <%= "Paraguay".equals(clienteEditar.getEstado()) ? "selected" : "" %>>Paraguay</option>
                                <option value="Perú" <%= "Perú".equals(clienteEditar.getEstado()) ? "selected" : "" %>>Perú</option>
                                <option value="Puerto Rico" <%= "Puerto Rico".equals(clienteEditar.getEstado()) ? "selected" : "" %>>Puerto Rico</option>
                                <option value="República Dominicana" <%= "República Dominicana".equals(clienteEditar.getEstado()) ? "selected" : "" %>>República Dominicana</option>
                                <option value="Uruguay" <%= "Uruguay".equals(clienteEditar.getEstado()) ? "selected" : "" %>>Uruguay</option>
                                <option value="Venezuela" <%= "Venezuela".equals(clienteEditar.getEstado()) ? "selected" : "" %>>Venezuela</option>
                            </optgroup>
                            <optgroup label="🌍 Europa">
                                <option value="Alemania" <%= "Alemania".equals(clienteEditar.getEstado()) ? "selected" : "" %>>Alemania</option>
                                <option value="Austria" <%= "Austria".equals(clienteEditar.getEstado()) ? "selected" : "" %>>Austria</option>
                                <option value="Bélgica" <%= "Bélgica".equals(clienteEditar.getEstado()) ? "selected" : "" %>>Bélgica</option>
                                <option value="Dinamarca" <%= "Dinamarca".equals(clienteEditar.getEstado()) ? "selected" : "" %>>Dinamarca</option>
                                <option value="España" <%= "España".equals(clienteEditar.getEstado()) ? "selected" : "" %>>España</option>
                                <option value="Francia" <%= "Francia".equals(clienteEditar.getEstado()) ? "selected" : "" %>>Francia</option>
                                <option value="Grecia" <%= "Grecia".equals(clienteEditar.getEstado()) ? "selected" : "" %>>Grecia</option>
                                <option value="Irlanda" <%= "Irlanda".equals(clienteEditar.getEstado()) ? "selected" : "" %>>Irlanda</option>
                                <option value="Italia" <%= "Italia".equals(clienteEditar.getEstado()) ? "selected" : "" %>>Italia</option>
                                <option value="Noruega" <%= "Noruega".equals(clienteEditar.getEstado()) ? "selected" : "" %>>Noruega</option>
                                <option value="Países Bajos" <%= "Países Bajos".equals(clienteEditar.getEstado()) ? "selected" : "" %>>Países Bajos</option>
                                <option value="Polonia" <%= "Polonia".equals(clienteEditar.getEstado()) ? "selected" : "" %>>Polonia</option>
                                <option value="Portugal" <%= "Portugal".equals(clienteEditar.getEstado()) ? "selected" : "" %>>Portugal</option>
                                <option value="Reino Unido" <%= "Reino Unido".equals(clienteEditar.getEstado()) ? "selected" : "" %>>Reino Unido</option>
                                <option value="Rusia" <%= "Rusia".equals(clienteEditar.getEstado()) ? "selected" : "" %>>Rusia</option>
                                <option value="Suecia" <%= "Suecia".equals(clienteEditar.getEstado()) ? "selected" : "" %>>Suecia</option>
                                <option value="Suiza" <%= "Suiza".equals(clienteEditar.getEstado()) ? "selected" : "" %>>Suiza</option>
                                <option value="Ucrania" <%= "Ucrania".equals(clienteEditar.getEstado()) ? "selected" : "" %>>Ucrania</option>
                            </optgroup>
                            <optgroup label="🌏 Asia">
                                <option value="China" <%= "China".equals(clienteEditar.getEstado()) ? "selected" : "" %>>China</option>
                                <option value="Corea del Sur" <%= "Corea del Sur".equals(clienteEditar.getEstado()) ? "selected" : "" %>>Corea del Sur</option>
                                <option value="Filipinas" <%= "Filipinas".equals(clienteEditar.getEstado()) ? "selected" : "" %>>Filipinas</option>
                                <option value="India" <%= "India".equals(clienteEditar.getEstado()) ? "selected" : "" %>>India</option>
                                <option value="Indonesia" <%= "Indonesia".equals(clienteEditar.getEstado()) ? "selected" : "" %>>Indonesia</option>
                                <option value="Japón" <%= "Japón".equals(clienteEditar.getEstado()) ? "selected" : "" %>>Japón</option>
                                <option value="Malasia" <%= "Malasia".equals(clienteEditar.getEstado()) ? "selected" : "" %>>Malasia</option>
                                <option value="Singapur" <%= "Singapur".equals(clienteEditar.getEstado()) ? "selected" : "" %>>Singapur</option>
                                <option value="Tailandia" <%= "Tailandia".equals(clienteEditar.getEstado()) ? "selected" : "" %>>Tailandia</option>
                                <option value="Vietnam" <%= "Vietnam".equals(clienteEditar.getEstado()) ? "selected" : "" %>>Vietnam</option>
                            </optgroup>
                            <optgroup label="🌍 África">
                                <option value="Argelia" <%= "Argelia".equals(clienteEditar.getEstado()) ? "selected" : "" %>>Argelia</option>
                                <option value="Egipto" <%= "Egipto".equals(clienteEditar.getEstado()) ? "selected" : "" %>>Egipto</option>
                                <option value="Kenia" <%= "Kenia".equals(clienteEditar.getEstado()) ? "selected" : "" %>>Kenia</option>
                                <option value="Marruecos" <%= "Marruecos".equals(clienteEditar.getEstado()) ? "selected" : "" %>>Marruecos</option>
                                <option value="Nigeria" <%= "Nigeria".equals(clienteEditar.getEstado()) ? "selected" : "" %>>Nigeria</option>
                                <option value="Sudáfrica" <%= "Sudáfrica".equals(clienteEditar.getEstado()) ? "selected" : "" %>>Sudáfrica</option>
                            </optgroup>
                            <optgroup label="🌏 Oceanía">
                                <option value="Australia" <%= "Australia".equals(clienteEditar.getEstado()) ? "selected" : "" %>>Australia</option>
                                <option value="Nueva Zelanda" <%= "Nueva Zelanda".equals(clienteEditar.getEstado()) ? "selected" : "" %>>Nueva Zelanda</option>
                            </optgroup>
                        </select>
                    </div>

                    <!-- 🔥 DESPUÉS: CIUDAD (dependiente del país) -->
                    <div class="form-group">
                        <label>Ciudad:</label>
                        <select name="ciudad" id="ciudadEditar" required>
                            <option value="">-- Selecciona un país primero --</option>
                        </select>
                    </div>

                    <div class="form-group">
                        <label>Código postal (ZIP):</label>
                        <input type="number" name="zip" required min="1000" max="99999" value="<%= clienteEditar.getZip() %>">
                    </div>

                    <div style="display: flex; gap: 10px; margin-top: 20px;">
                        <button type="submit" class="btn-primary" style="background-color: #2980b9;">💾 Guardar cambios</button>
                        <a href="ClienteServlet" class="btn" style="background-color: #95a5a6;">Cancelar</a>
                    </div>
                </form>
            </div>
            
            <!-- 🔥 SCRIPT PARA CARGAR LAS CIUDADES DEL PAÍS SELECCIONADO AL EDITAR -->
            <script>
                window.onload = function() {
                    const paisSelect = document.getElementById('paisEditar');
                    if (paisSelect.value) {
                        actualizarCiudades(paisSelect, document.getElementById('ciudadEditar'));
                        // Preseleccionar la ciudad actual
                        const ciudadSelect = document.getElementById('ciudadEditar');
                        const ciudadActual = "<%= clienteEditar.getCiudad() != null ? clienteEditar.getCiudad() : "" %>";
                        for (let i = 0; i < ciudadSelect.options.length; i++) {
                            if (ciudadSelect.options[i].value === ciudadActual) {
                                ciudadSelect.selectedIndex = i;
                                break;
                            }
                        }
                    }
                };
            </script>
        <% } %>

        <h2>👥 Lista de Clientes</h2>
        <p style="color: #7f8c8d; margin-bottom: 15px;">💡 Los clientes están ordenados por <b>total comprado</b>.</p>

        <div class="form-container" style="background:#f8f9fa; margin-bottom:20px; padding: 15px;">
            <form action="ClienteServlet" method="get" style="display: flex; gap: 10px; align-items: center;">
                <input type="text" name="q" value="<%= filtroQ %>" 
                       placeholder="Buscar por nombre, email o teléfono..." 
                       style="flex: 1; padding: 10px; border: 1px solid #ccc; border-radius: 5px; font-size: 1em;">
                <button type="submit" class="btn-primary" style="background-color: #2980b9;">🔍 Buscar</button>
                <a href="ClienteServlet" class="btn" style="background-color: #95a5a6;">🔄 Limpiar</a>
            </form>
        </div>

        <div class="tabla-scroll">
            <table class="tabla-clientes">
                <thead>
                    <tr>
                        <th>ID</th>
                        <th>Nombre Completo</th>
                        <th>Email</th>
                        <th>📱 Teléfono</th>
                        <th>Ciudad</th>
                        <th>Categoría</th>
                        <th>Descuento</th>
                        <th>📦 Pedidos</th>
                        <th>💵 Total Comprado</th>
                        <th>Sugerencia</th>
                        <th>Acciones</th>
                    </tr>
                </thead>
                <tbody>                   
                    <% if (clientes != null && !clientes.isEmpty()) {
                        for (Cliente c : clientes) {
                            String catNombre = c.getCategoriaNombre() != null ? c.getCategoriaNombre() : "Sin categoría";
                            double desc = c.getDescuento();
                            int pedidos = c.getTotalPedidos();
                            double totalComprado = c.getTotalComprado();

                            String colorCat = desc >= 20 ? "#8e44ad" : desc >= 15 ? "#f39c12" : desc >= 10 ? "#95a5a6" : desc >= 5  ? "#cd7f32" : "#7f8c8d";
                            
                            String catSugerida;
                            String colorSugerida;
                            if (totalComprado >= 5000)      { catSugerida = "Platino"; colorSugerida = "#8e44ad"; }
                            else if (totalComprado >= 2000) { catSugerida = "Oro";     colorSugerida = "#f39c12"; }
                            else if (totalComprado >= 500)  { catSugerida = "Plata";   colorSugerida = "#95a5a6"; }
                            else if (totalComprado >= 100)  { catSugerida = "Bronce";  colorSugerida = "#cd7f32"; }
                            else                            { catSugerida = "Regular"; colorSugerida = "#7f8c8d"; }
                            boolean upgrade = !catSugerida.equalsIgnoreCase(catNombre);
                    %>
                        <tr>
                            <td><%= c.getCustomerId() %></td>
                            <td><b><%= c.getNombre() %></b></td>
                            <td><%= c.getEmail() %></td>
                            <td><% if (c.getTelefono() != null && !c.getTelefono().isEmpty()) { %><span style="white-space: nowrap;">📞 <%= c.getTelefono() %></span><% } else { %><span style="color: #999;">—</span><% } %></td>
                            <td><%= c.getCiudad() != null ? c.getCiudad() : "-" %></td>
                            <td><span class="badge" style="background-color: <%= colorCat %>;"><%= catNombre %></span></td>
                            <td><% if (desc > 0) { %><b style="color: #27ae60;"><%= (int) desc %>%</b><% } else { %><span style="color: #999;">Sin descuento</span><% } %></td>
                            <td>
                                <% if (pedidos > 0) { %>
                                    <span style="background: #3498db; color: white; padding: 3px 10px; border-radius: 10px; font-weight: bold;"><%= pedidos %></span>
                                <% } else { %>
                                    <span style="color: #999;">0</span>
                                <% } %>
                            </td>
                            <td><% if (totalComprado > 0) { %><b style="color: #27ae60;">$<%= String.format("%.2f", totalComprado) %></b><% } else { %><span style="color: #999;">$0.00</span><% } %></td>
                            <td>
                                <% if (upgrade) { %>
                                    <span style="background: <%= colorSugerida %>; color: white; padding: 4px 10px; border-radius: 12px; font-size: 0.85em; font-weight: bold; white-space: nowrap;">⬆️ <%= catSugerida %></span>
                                <% } else { %>
                                    <span style="color: #27ae60; font-size: 0.85em;">✅ Al día</span>
                                <% } %>
                            </td>
                            <td style="white-space: nowrap;">
                                <div style="display: flex; gap: 3px; align-items: center;">
                                    
                                    <a href="ClienteServlet?accion=editar&id=<%= c.getCustomerId() %>" 
                                       class="btn" 
                                       style="background-color: #3498db; padding: 5px 8px; font-size: 0.75em;" 
                                       title="Editar Cliente">
                                       ✏️ Editar
                                    </a>
                                    
                                    <form action="ClienteServlet" method="get" style="display: flex; gap: 2px; margin: 0;">
                                        <input type="hidden" name="accion" value="cambiarCategoria">
                                        <input type="hidden" name="customerId" value="<%= c.getCustomerId() %>">
                                        <select name="categoryId" style="padding: 4px; font-size: 0.75em; min-width: 100px; max-width: 120px;">
                                            <% if (categoriasCliente != null) for (CategoriaCliente cat : categoriasCliente) { %>
                                                <option value="<%= cat.getCategoryId() %>" <%= cat.getCategoryId() == c.getCategoryId() ? "selected" : "" %>>
                                                    <%= cat.getEtiqueta() %>
                                                </option>
                                            <% } %>
                                        </select>
                                        <button type="submit" class="btn" style="background-color: #9b59b6; padding: 4px 6px; font-size: 0.75em;">Cambiar</button>
                                    </form>

                                    <% if (esAdmin) { %>
                                        <a href="ClienteServlet?accion=eliminar&id=<%= c.getCustomerId() %>" 
                                           class="btn-eliminar" 
                                           style="padding: 5px 8px; font-size: 0.75em;" 
                                           onclick="return confirm('¿Desactivar este cliente?')"
                                           title="Eliminar Cliente">
                                           🗑️ Eliminar
                                        </a>
                                    <% } %>
                                </div>
                            </td>
                        </tr>
                    <% } 
                    } else { %>
                        <tr><td colspan="11" style="text-align:center; color:#7f8c8d; padding:20px;">
                            No se encontraron clientes con esos filtros.
                        </td></tr>
                    <% } %>
                </tbody>
            </table>
        </div>

        <h2>➕ Agregar nuevo cliente</h2>
        <div class="form-container">
            <form action="ClienteServlet" method="post">
                <div style="display: flex; gap: 10px;">
                    <div class="form-group" style="flex: 1;">
                        <label>Nombre:</label>
                        <input type="text" name="nombre" required value="<%= regNombre %>" style="<%= styleNombre %>">
                    </div>
                    <div class="form-group" style="flex: 1;">
                        <label>Apellido:</label>
                        <input type="text" name="apellido" required value="<%= regApellido %>">
                    </div>
                </div>
                <div class="form-group">
                    <label>Correo electrónico:</label>
                    <input type="email" name="email" required value="<%= regEmail %>" style="<%= styleEmail %>">
                </div>

                <!-- 🔥 PRIMERO: PAÍS -->
                <div class="form-group">
                    <label>País:</label>
                    <select name="estado" id="paisAgregar" required onchange="actualizarCiudades(this, document.getElementById('ciudadAgregar'))">
                        <option value="">-- Selecciona un país --</option>
                        <optgroup label="🌎 América">
                            <option value="Argentina" <%= "Argentina".equals(regEstado) ? "selected" : "" %>>Argentina</option>
                            <option value="Bolivia" <%= "Bolivia".equals(regEstado) ? "selected" : "" %>>Bolivia</option>
                            <option value="Brasil" <%= "Brasil".equals(regEstado) ? "selected" : "" %>>Brasil</option>
                            <option value="Canadá" <%= "Canadá".equals(regEstado) ? "selected" : "" %>>Canadá</option>
                            <option value="Chile" <%= "Chile".equals(regEstado) ? "selected" : "" %>>Chile</option>
                            <option value="Colombia" <%= "Colombia".equals(regEstado) ? "selected" : "" %>>Colombia</option>
                            <option value="Costa Rica" <%= "Costa Rica".equals(regEstado) ? "selected" : "" %>>Costa Rica</option>
                            <option value="Cuba" <%= "Cuba".equals(regEstado) ? "selected" : "" %>>Cuba</option>
                            <option value="Ecuador" <%= "Ecuador".equals(regEstado) ? "selected" : "" %>>Ecuador</option>
                            <option value="El Salvador" <%= "El Salvador".equals(regEstado) ? "selected" : "" %>>El Salvador</option>
                            <option value="Estados Unidos" <%= "Estados Unidos".equals(regEstado) ? "selected" : "" %>>Estados Unidos</option>
                            <option value="Guatemala" <%= "Guatemala".equals(regEstado) ? "selected" : "" %>>Guatemala</option>
                            <option value="Honduras" <%= "Honduras".equals(regEstado) ? "selected" : "" %>>Honduras</option>
                            <option value="México" <%= "México".equals(regEstado) ? "selected" : "" %>>México</option>
                            <option value="Nicaragua" <%= "Nicaragua".equals(regEstado) ? "selected" : "" %>>Nicaragua</option>
                            <option value="Panamá" <%= "Panamá".equals(regEstado) ? "selected" : "" %>>Panamá</option>
                            <option value="Paraguay" <%= "Paraguay".equals(regEstado) ? "selected" : "" %>>Paraguay</option>
                            <option value="Perú" <%= "Perú".equals(regEstado) ? "selected" : "" %>>Perú</option>
                            <option value="Puerto Rico" <%= "Puerto Rico".equals(regEstado) ? "selected" : "" %>>Puerto Rico</option>
                            <option value="República Dominicana" <%= "República Dominicana".equals(regEstado) ? "selected" : "" %>>República Dominicana</option>
                            <option value="Uruguay" <%= "Uruguay".equals(regEstado) ? "selected" : "" %>>Uruguay</option>
                            <option value="Venezuela" <%= "Venezuela".equals(regEstado) ? "selected" : "" %>>Venezuela</option>
                        </optgroup>
                        <optgroup label="🌍 Europa">
                            <option value="Alemania" <%= "Alemania".equals(regEstado) ? "selected" : "" %>>Alemania</option>
                            <option value="Austria" <%= "Austria".equals(regEstado) ? "selected" : "" %>>Austria</option>
                            <option value="Bélgica" <%= "Bélgica".equals(regEstado) ? "selected" : "" %>>Bélgica</option>
                            <option value="Dinamarca" <%= "Dinamarca".equals(regEstado) ? "selected" : "" %>>Dinamarca</option>
                            <option value="España" <%= "España".equals(regEstado) ? "selected" : "" %>>España</option>
                            <option value="Francia" <%= "Francia".equals(regEstado) ? "selected" : "" %>>Francia</option>
                            <option value="Grecia" <%= "Grecia".equals(regEstado) ? "selected" : "" %>>Grecia</option>
                            <option value="Irlanda" <%= "Irlanda".equals(regEstado) ? "selected" : "" %>>Irlanda</option>
                            <option value="Italia" <%= "Italia".equals(regEstado) ? "selected" : "" %>>Italia</option>
                            <option value="Noruega" <%= "Noruega".equals(regEstado) ? "selected" : "" %>>Noruega</option>
                            <option value="Países Bajos" <%= "Países Bajos".equals(regEstado) ? "selected" : "" %>>Países Bajos</option>
                            <option value="Polonia" <%= "Polonia".equals(regEstado) ? "selected" : "" %>>Polonia</option>
                            <option value="Portugal" <%= "Portugal".equals(regEstado) ? "selected" : "" %>>Portugal</option>
                            <option value="Reino Unido" <%= "Reino Unido".equals(regEstado) ? "selected" : "" %>>Reino Unido</option>
                            <option value="Rusia" <%= "Rusia".equals(regEstado) ? "selected" : "" %>>Rusia</option>
                            <option value="Suecia" <%= "Suecia".equals(regEstado) ? "selected" : "" %>>Suecia</option>
                            <option value="Suiza" <%= "Suiza".equals(regEstado) ? "selected" : "" %>>Suiza</option>
                            <option value="Ucrania" <%= "Ucrania".equals(regEstado) ? "selected" : "" %>>Ucrania</option>
                        </optgroup>
                        <optgroup label="🌏 Asia">
                            <option value="China" <%= "China".equals(regEstado) ? "selected" : "" %>>China</option>
                            <option value="Corea del Sur" <%= "Corea del Sur".equals(regEstado) ? "selected" : "" %>>Corea del Sur</option>
                            <option value="Filipinas" <%= "Filipinas".equals(regEstado) ? "selected" : "" %>>Filipinas</option>
                            <option value="India" <%= "India".equals(regEstado) ? "selected" : "" %>>India</option>
                            <option value="Indonesia" <%= "Indonesia".equals(regEstado) ? "selected" : "" %>>Indonesia</option>
                            <option value="Japón" <%= "Japón".equals(regEstado) ? "selected" : "" %>>Japón</option>
                            <option value="Malasia" <%= "Malasia".equals(regEstado) ? "selected" : "" %>>Malasia</option>
                            <option value="Singapur" <%= "Singapur".equals(regEstado) ? "selected" : "" %>>Singapur</option>
                            <option value="Tailandia" <%= "Tailandia".equals(regEstado) ? "selected" : "" %>>Tailandia</option>
                            <option value="Vietnam" <%= "Vietnam".equals(regEstado) ? "selected" : "" %>>Vietnam</option>
                        </optgroup>
                        <optgroup label="🌍 África">
                            <option value="Argelia" <%= "Argelia".equals(regEstado) ? "selected" : "" %>>Argelia</option>
                            <option value="Egipto" <%= "Egipto".equals(regEstado) ? "selected" : "" %>>Egipto</option>
                            <option value="Kenia" <%= "Kenia".equals(regEstado) ? "selected" : "" %>>Kenia</option>
                            <option value="Marruecos" <%= "Marruecos".equals(regEstado) ? "selected" : "" %>>Marruecos</option>
                            <option value="Nigeria" <%= "Nigeria".equals(regEstado) ? "selected" : "" %>>Nigeria</option>
                            <option value="Sudáfrica" <%= "Sudáfrica".equals(regEstado) ? "selected" : "" %>>Sudáfrica</option>
                        </optgroup>
                        <optgroup label="🌏 Oceanía">
                            <option value="Australia" <%= "Australia".equals(regEstado) ? "selected" : "" %>>Australia</option>
                            <option value="Nueva Zelanda" <%= "Nueva Zelanda".equals(regEstado) ? "selected" : "" %>>Nueva Zelanda</option>
                        </optgroup>
                    </select>
                </div>

                <!-- 🔥 DESPUÉS: CIUDAD -->
                <div class="form-group">
                    <label>Ciudad:</label>
                    <select name="ciudad" id="ciudadAgregar" required>
                        <option value="">-- Selecciona un país primero --</option>
                    </select>
                </div>

                <div class="form-group">
                    <label>Código postal (ZIP):</label>
                    <input type="number" name="zip" required min="1000" max="99999" value="<%= regZip %>">
                </div>
                <div class="form-group">
                    <label>Teléfono (opcional):</label>
                    <input type="tel" name="telefono" pattern="^\+505[\s\-]?[0-9\s\-]{8,15}$" title="Debe empezar con +505" placeholder="Ej: +505 8888-8888" value="<%= regTelefono %>" style="<%= styleTel %>">
                </div>
                <div class="form-group" style="background:#fef9e7; padding:15px; border-radius:5px; border:1px solid #f39c12;">
                    <label style="color:#b9770e;"><b>🔐 Contraseña provisional:</b></label>
                    <input type="text" name="password" required minlength="6" placeholder="Ej: cliente123" style="border-color:#f39c12;" value="<%= regPassword %>">
                    <p style="color:#b9770e; font-size:0.85em; margin-top:5px;">⚠️ Se le pedirá al cliente cambiarla en su primer inicio de sesión.</p>
                </div>
                
                <div style="background:#f8f9fa; padding:15px; border-radius:5px; border:1px solid #ddd; margin-top:15px;">
                    <p style="margin-top:0; color:#7f8c8d;"><b>💳 Datos de tarjeta (Opcional):</b></p>
                    <div class="form-group">
                        <label>Número de tarjeta:</label>
                        <input type="text" name="tarjeta" pattern="[0-9]{16}" title="Exactamente 16 dígitos numéricos" value="<%= regTarjeta %>" style="<%= styleTarjeta %>">
                    </div>
                    <div class="form-group">
                        <label>Tipo de tarjeta:</label>
                        <select name="tipo">
                            <option value="">-- Selecciona --</option>
                            <option value="VISA" <%= "VISA".equals(regTipo) ? "selected" : "" %>>VISA</option>
                            <option value="MC" <%= "MC".equals(regTipo) ? "selected" : "" %>>MasterCard</option>
                            <option value="AMEX" <%= "AMEX".equals(regTipo) ? "selected" : "" %>>American Express</option>
                            <option value="Discover" <%= "Discover".equals(regTipo) ? "selected" : "" %>>Discover</option>
                        </select>
                    </div>
                    <div style="display:flex; gap:10px;">
                        <div class="form-group" style="flex:1;">
                            <label>Mes de expiración:</label>
                            <input type="number" name="mes" min="1" max="12" value="<%= regMes %>">
                        </div>
                        <div class="form-group" style="flex:1;">
                            <label>Año de expiración:</label>
                            <input type="number" name="anio" min="2026" max="2100" value="<%= regAnio %>">
                        </div>
                    </div>
                </div>

                <button type="submit" class="btn-primary" style="margin-top:20px;">Agregar cliente</button>
            </form>
        </div>
    </main>
</body>
</html>