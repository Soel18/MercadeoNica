<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%
    String regNombre   = (String) request.getAttribute("reg_nombre");
    String regApellido = (String) request.getAttribute("reg_apellido");
    String regEmail    = (String) request.getAttribute("reg_email");
    String regCiudad   = (String) request.getAttribute("reg_ciudad");
    String regEstado   = (String) request.getAttribute("reg_estado");
    String regZip      = (String) request.getAttribute("reg_zip");
    String regTelefono = (String) request.getAttribute("reg_telefono");
    String errorField  = (String) request.getAttribute("error_field");
    
    if (regNombre == null) regNombre = "";
    if (regApellido == null) regApellido = "";
    if (regEmail == null) regEmail = "";
    if (regCiudad == null) regCiudad = "";
    if (regEstado == null) regEstado = "";
    if (regZip == null) regZip = "";
    if (regTelefono == null) regTelefono = "";

    String styleEmail = "email".equals(errorField) ? 
        "border: 2px solid #e74c3c; background-color: #fdecea; box-shadow: 0 0 8px rgba(231, 76, 60, 0.6);" : "";
%>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <title>Registro de Cliente - MercadeoNica</title>
    <link rel="stylesheet" href="css/estilos.css">
    <script>
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

    <div class="login-container" style="max-width: 500px;">
        <h1>🛒 MercadeoNica</h1>
        <h2>Crear cuenta nueva</h2>

        <% String error = (String) request.getAttribute("error"); %>
        <% if (error != null) { %>
            <div class="error">⚠️ <%= error %></div>
        <% } %>

        <form action="ClienteRegistroServlet" method="post">
            <label>Nombre:</label>
            <input type="text" name="nombre" required value="<%= regNombre %>">

            <label>Apellido:</label>
            <input type="text" name="apellido" required value="<%= regApellido %>">

            <label>Correo electrónico:</label>
            <input type="email" name="email" required value="<%= regEmail %>" style="<%= styleEmail %>">

            <!-- 🔥 PRIMERO: PAÍS -->
            <label>País:</label>
            <select name="estado" id="paisRegistro" required onchange="actualizarCiudades(this, document.getElementById('ciudadRegistro'))">
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

            <!-- 🔥 DESPUÉS: CIUDAD -->
            <label>Ciudad:</label>
            <select name="ciudad" id="ciudadRegistro" required>
                <option value="">-- Selecciona un país primero --</option>
            </select>

            <label>Código Postal (ZIP):</label>
            <input type="number" name="zip" required min="1000" max="99999" value="<%= regZip %>">

            <label>Teléfono (opcional):</label>
            <input type="tel" name="telefono"
                   pattern="^\+505[\s\-]?[0-9\s\-]{8,15}$"
                   title="Debe empezar con +505"
                   placeholder="Ej: +505 8888-8888"
                   value="<%= regTelefono %>">

            <label>Contraseña:</label>
            <input type="password" name="password" required minlength="6">

            <button type="submit">Registrarme</button>
        </form>

        <p class="hint">
            ¿Ya tienes cuenta? <a href="login.jsp">Inicia sesión</a>
        </p>
    </div>

</body>
</html>