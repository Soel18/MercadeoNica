package com.mercadeonica.controlador;

import com.mercadeonica.dao.ClienteDAO;
import com.mercadeonica.modelo.Cliente;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

import java.io.IOException;
import java.sql.SQLException;

@WebServlet(name = "ClienteRegistroServlet", urlPatterns = {"/ClienteRegistroServlet"})
public class ClienteRegistroServlet extends HttpServlet {

    private static final String PHONE_REGEX = "^\\+505[\\s\\-]?[0-9\\s\\-]{8,15}$";

    private String formatearTitulo(String texto) {
        if (texto == null || texto.trim().isEmpty()) return texto;
        String[] palabras = texto.trim().toLowerCase().split("\\s+");
        StringBuilder sb = new StringBuilder();
        for (String palabra : palabras) {
            if (palabra.length() > 0) {
                sb.append(Character.toUpperCase(palabra.charAt(0)))
                  .append(palabra.substring(1))
                  .append(" ");
            }
        }
        return sb.toString().trim();
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        System.out.println("========== ClienteRegistroServlet.doPost ==========");

        try {
            String nombre   = formatearTitulo(request.getParameter("nombre"));
            String apellido = formatearTitulo(request.getParameter("apellido"));
            String email    = request.getParameter("email");
            String ciudad   = formatearTitulo(request.getParameter("ciudad"));
            String estado   = formatearTitulo(request.getParameter("estado"));
            int    zip      = Integer.parseInt(request.getParameter("zip"));
            String telefono = request.getParameter("telefono");
            String password = request.getParameter("password");

            if (telefono != null) telefono = telefono.trim();
            if (telefono != null && telefono.isEmpty()) telefono = null;

            // 🔥 GUARDAR DATOS DEL FORMULARIO EN EL REQUEST PARA MANTENERLOS
            request.setAttribute("reg_nombre", nombre);
            request.setAttribute("reg_apellido", apellido);
            request.setAttribute("reg_email", email);
            request.setAttribute("reg_ciudad", ciudad);
            request.setAttribute("reg_estado", estado);
            request.setAttribute("reg_zip", String.valueOf(zip));
            request.setAttribute("reg_telefono", telefono);

            // Validar que nombre y apellido no estén vacíos
            if (nombre == null || nombre.trim().isEmpty() || 
                apellido == null || apellido.trim().isEmpty()) {
                request.setAttribute("error", "Nombre y apellido son obligatorios.");
                request.setAttribute("error_field", "nombre");
                request.getRequestDispatcher("cliente-registro.jsp").forward(request, response);
                return;
            }

            if (telefono != null && !telefono.matches(PHONE_REGEX)) {
                request.setAttribute("error", "El teléfono debe tener un formato válido. Ej: +505 8888-8888");
                request.setAttribute("error_field", "telefono");
                request.getRequestDispatcher("cliente-registro.jsp").forward(request, response);
                return;
            }

            ClienteDAO dao = new ClienteDAO();

            // 🔥 SI EL CORREO YA EXISTE, MANTENER DATOS Y RESALTAR EL CAMPO
            if (dao.buscarPorEmail(email) != null) {
                request.setAttribute("error", "⚠️ El correo ya está registrado. Por favor, ingresa otro.");
                request.setAttribute("error_field", "email");
                request.getRequestDispatcher("cliente-registro.jsp").forward(request, response);
                return;
            }

            // 🔥 CONCATENAR NOMBRE Y APELLIDO
            String nombreCompleto = nombre + " " + apellido;

            // 🔥 Se llama al DAO con el nombre completo
            boolean ok = dao.registrar(nombreCompleto, email, ciudad, estado, zip, telefono, password);

            if (ok) {
                Cliente cliente = dao.login(email, password);
                if (cliente != null) {
                    HttpSession session = request.getSession();
                    session.setAttribute("cliente", cliente);
                    session.setAttribute("clienteNombre", cliente.getNombre());
                    session.setAttribute("clienteId", cliente.getCustomerId());
                    response.sendRedirect("cliente-menu.jsp");
                } else {
                    request.setAttribute("mensaje", "Registro exitoso. Inicia sesión.");
                    request.getRequestDispatcher("login.jsp").forward(request, response);
                }
            } else {
                request.setAttribute("error", "Error al registrar. Verifica los datos.");
                request.getRequestDispatcher("cliente-registro.jsp").forward(request, response);
            }

        } catch (SQLException sqle) {
            String mensajeUsuario;
            switch (sqle.getErrorCode()) {
                case 2812: mensajeUsuario = "Error de configuración: falta un procedimiento en la BD."; break;
                case 2627: mensajeUsuario = "Ese correo ya está registrado."; break;
                case 547:  mensajeUsuario = "Datos inválidos (revisa el ZIP o email)."; break;
                default:   mensajeUsuario = "Error inesperado al registrar.";
            }
            request.setAttribute("error", mensajeUsuario);
            request.getRequestDispatcher("cliente-registro.jsp").forward(request, response);

        } catch (NumberFormatException nfe) {
            request.setAttribute("error", "El código postal (ZIP) debe ser un número válido.");
            request.getRequestDispatcher("cliente-registro.jsp").forward(request, response);

        } catch (Exception e) {
            request.setAttribute("error", "Error: " + e.getMessage());
            request.getRequestDispatcher("cliente-registro.jsp").forward(request, response);
        }
    }

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        response.sendRedirect("cliente-registro.jsp");
    }
}