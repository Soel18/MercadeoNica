package com.mercadeonica.controlador;

import com.mercadeonica.dao.VendedorDAO;
import com.mercadeonica.modelo.Vendedor;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

import java.io.IOException;

/**
 * Servlet que procesa el formulario de login.
 */
@WebServlet(name = "LoginServlet", urlPatterns = {"/LoginServlet"})
public class LoginServlet extends HttpServlet {

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        // 1. Obtener los datos del formulario
        String email    = request.getParameter("email");
        String password = request.getParameter("password");

        System.out.println("🔐 Intento de login: " + email);

        // 2. Validar con la BD
        VendedorDAO dao = new VendedorDAO();
        Vendedor vendedor = dao.login(email, password);

        if (vendedor != null) {
            // 3a. Login exitoso → crear sesión
            HttpSession session = request.getSession();
            session.setAttribute("vendedor", vendedor);
            session.setAttribute("nombreUsuario", vendedor.getNombre());
            session.setAttribute("rolUsuario", vendedor.getRol());

            System.out.println("✅ Sesión creada para: " + vendedor.getNombre());

            // Redirigir al menú
            response.sendRedirect("menu.jsp");
        } else {
            // 3b. Login fallido → volver al login con error
            request.setAttribute("error", "Credenciales inválidas o usuario inactivo.");
            request.getRequestDispatcher("login.jsp").forward(request, response);
        }
    }

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        // Si acceden por GET, redirigir al login
        response.sendRedirect("login.jsp");
    }
}