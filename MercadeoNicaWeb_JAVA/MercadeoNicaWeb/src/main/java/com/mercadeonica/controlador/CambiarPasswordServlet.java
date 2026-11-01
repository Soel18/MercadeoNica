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

@WebServlet(name = "CambiarPasswordServlet", urlPatterns = {"/CambiarPasswordServlet"})
public class CambiarPasswordServlet extends HttpServlet {

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession session = request.getSession(false);
        Cliente cliente = (session != null) ? (Cliente) session.getAttribute("cliente") : null;

        if (cliente == null) {
            response.sendRedirect("login.jsp");
            return;
        }

        String nueva = request.getParameter("nuevaPassword");
        String confirma = request.getParameter("confirmarPassword");

        if (nueva == null || nueva.trim().isEmpty() || confirma == null || confirma.trim().isEmpty()) {
            request.setAttribute("error", "Debes llenar ambos campos.");
            request.getRequestDispatcher("cliente-cambiar-password.jsp").forward(request, response);
            return;
        }

        if (!nueva.equals(confirma)) {
            request.setAttribute("error", "Las contraseñas no coinciden.");
            request.getRequestDispatcher("cliente-cambiar-password.jsp").forward(request, response);
            return;
        }

        if (nueva.length() < 6) {
            request.setAttribute("error", "La contraseña debe tener al menos 6 caracteres.");
            request.getRequestDispatcher("cliente-cambiar-password.jsp").forward(request, response);
            return;
        }

        ClienteDAO dao = new ClienteDAO();
        boolean ok = dao.actualizarPassword(cliente.getCustomerId(), nueva);

        if (ok) {
            // Actualizamos el objeto en sesión para que ya no pida cambiarla
            cliente.setPasswordHash(nueva);
            cliente.setDebeCambiarPassword(false);
            session.setAttribute("cliente", cliente);
            
            System.out.println("✅ Contraseña cambiada por el cliente: " + cliente.getNombre());
            response.sendRedirect("cliente-menu.jsp");
        } else {
            request.setAttribute("error", "Error al guardar en la base de datos. Intenta de nuevo.");
            request.getRequestDispatcher("cliente-cambiar-password.jsp").forward(request, response);
        }
    }
}