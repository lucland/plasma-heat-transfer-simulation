# Phase Change Modeling Approaches

This document outlines the approaches considered for modeling phase changes (melting, vaporization) in the plasma heat transfer simulation.

## 1. Current Approach (Simplified "Available Energy")

*   **Mechanism:** Calculates temperature first using `solve_time_step` (incorporating an effective heat capacity \(c_{p,eff}\) that attempts to smooth out latent heat effects). Then, `update_phase_change_fractions` explicitly checks if the calculated temperature \(T\) exceeds a phase change temperature (\(T_{phase}\)). If it does, it calculates the "available energy" above \(T_{phase}\) (\(\Delta E \approx m c_p (T - T_{phase})\)) and compares it to the remaining latent heat required (\(\Delta E_{latent} = m L (1 - f)\)). A portion of the available energy, up to the required latent heat, is used to update the phase fraction \(f\), effectively consuming latent heat.
*   **Order:** Melting is processed before vaporization.
*   **Pros:**
    *   Relatively simple to implement initially.
    *   Keeps the primary solver focused on temperature.
*   **Cons:**
    *   **Energy Conservation Issues:** The decoupling of the temperature solve (using \(c_{p,eff}\)) and the explicit fraction update can lead to inaccuracies in energy conservation, especially with large time steps or sharp interfaces. The energy "absorbed" by \(c_{p,eff}\) might not perfectly match the energy consumed in the fraction update.
    *   **Isotherm Handling:** Can struggle to maintain a sharp isotherm (the region exactly at \(T_{phase}\)). Temperatures might overshoot \(T_{phase}\) in the solver before being partially corrected by the fraction update.
    *   **Approximation:** Calculating available energy as \( m c_p (T - T_{phase}) \) is a simplification of the energy balance during the phase transition.

## 2. Proposed Approach: Enthalpy Method

*   **Mechanism:** Reformulates the heat equation to solve for specific enthalpy \(H\) instead of temperature \(T\). Enthalpy naturally incorporates both sensible heat (\(\int c_p dT\)) and latent heat (\(L\)). The relationship between enthalpy, temperature, and phase fraction (\(T(H)\), \(f(H)\)) is defined based on material properties.
    *   The discretized heat equation becomes an equation for \(H^{n+1}\).
    *   \( \rho \frac{H^{n+1} - H^n}{\Delta t} = \nabla \cdot (k \nabla T)^n + S^n \) (or an implicit/Crank-Nicolson version).
    *   Note that \(k\) and \(\nabla T\) still depend on temperature, requiring the \(T(H)\) relationship, introducing non-linearity. This is typically handled by using values from the previous time step or iteration (\(k(T^n)\), \(T^n\)) when solving for \(H^{n+1}\).
*   **Post-Solve:** After solving for the enthalpy field \(H^{n+1}\), the corresponding temperature \(T^{n+1}\) and phase fractions \(f^{n+1}\) are calculated directly from the \(T(H)\) and \(f(H)\) relationships for each cell.
*   **Pros:**
    *   **Improved Energy Conservation:** Enthalpy is the conserved variable, inherently including latent heat, leading to more accurate energy balance.
    *   **Robust Isotherm Handling:** Correctly handles the phase change occurring at a constant temperature over a range of enthalpy values.
    *   **Unified Equation:** Solves a single conservation equation for enthalpy.
*   **Cons:**
    *   **Increased Complexity:** Requires significant refactoring of the solver to work with enthalpy.
    *   **Non-linearity:** The dependence of properties (\(k\), \(c_p\)) on \(T(H)\) requires careful handling within the solver (e.g., using lagged coefficients or inner iterations).

## Decision

The **Enthalpy Method** (Approach 2) will be implemented to improve the physical accuracy and robustness of the phase change simulation, despite the increased implementation complexity. 