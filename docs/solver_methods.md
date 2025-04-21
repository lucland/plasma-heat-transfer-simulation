# Solver Methods for Heat Transfer Simulation

This document outlines the numerical methods used in the `HeatSolver` for the plasma heat transfer simulation, focusing on the time-stepping scheme.

## Initial Implementation: Forward Euler (Explicit)

The initial version of the `solve_time_step` function employed an explicit forward Euler finite difference method. This scheme calculates the temperature at the next time step ($T^{n+1}$) directly based on the temperatures at the current time step ($T^n$):

\[ \frac{T_{i,j}^{n+1} - T_{i,j}^{n}}{\Delta t} = \alpha \left( \nabla^2 T \right)_{i,j}^n + \frac{S_{i,j}^n}{\rho c_p} \]

Where:
- \( T_{i,j}^n \) is the temperature at radial node \( i \) and axial node \( j \) at time step \( n \).
- \( \Delta t \) is the time step size.
- \( \alpha = k / (\rho c_p) \) is the thermal diffusivity.
- \( \nabla^2 T \) is the Laplacian operator (discretized using central differences in cylindrical coordinates).
- \( S_{i,j}^n \) represents the source terms (plasma heating, radiation, convection).

**Advantages:**
- Simple to implement.
- Computationally inexpensive per time step.

**Disadvantages:**
- **Conditional Stability:** Explicit methods suffer from stability constraints. The simulation can become unstable (producing nonsensical results like oscillating or infinite temperatures) if the time step \( \Delta t \) is too large relative to the mesh spacing (\( \Delta r, \Delta z \)) and thermal diffusivity. The stability limit (related to the CFL condition) often forces the use of very small time steps, increasing the total simulation time.

## Refined Implementation: Crank-Nicolson (Implicit)

To overcome the stability limitations of the explicit method, the solver was refactored to use the **Crank-Nicolson** method. This is an implicit method that averages the spatial derivative terms between the current time step ($n$) and the next time step ($n+1$):

\[ \frac{T^{n+1} - T^{n}}{\Delta t} = \frac{\alpha}{2} \left( \nabla^2 T^n + \nabla^2 T^{n+1} \right) + \frac{S^n + S^{n+1}}{2 \rho c_p} \]

(Note: Source terms \( S \) are often treated explicitly or semi-implicitly for simplicity; here we assume they are evaluated predominantly at step \( n \) or averaged).

Rearranging the equation to group terms at \( n+1 \) on the left side results in a system of linear algebraic equations for the unknown temperatures \( T^{n+1} \) at each node:

\[ A T^{n+1} = b \]

Where:
- \( T^{n+1} \) is the vector of unknown temperatures at the next time step.
- \( A \) is a matrix derived from the discretized \( \nabla^2 T^{n+1} \) terms and the time derivative term.
- \( b \) is a vector containing known values from the current time step \( T^n \), source terms, and boundary conditions.

**Advantages:**
- **Unconditional Stability:** The Crank-Nicolson method is unconditionally stable for the linear heat equation, meaning larger time steps (\( \Delta t \)) can generally be used without causing numerical instability. This often leads to faster overall simulations despite the increased cost per step.
- **Second-Order Accuracy in Time:** It offers better temporal accuracy compared to the first-order forward Euler method.

**Disadvantages:**
- ** computationally More Complex:** Requires solving a system of linear equations \( A T^{n+1} = b \) at each time step.
- **Implementation Complexity:** Setting up the matrix \( A \) and solving the system is more complex than the direct calculation in the explicit method.

## Solving the Linear System: Successive Over-Relaxation (SOR)

Since the matrix \( A \) arising from the finite difference discretization is typically large, sparse, and often diagonally dominant, an iterative method is suitable for solving \( A T^{n+1} = b \). The **Successive Over-Relaxation (SOR)** method was chosen:

- It is an extension of the Gauss-Seidel method.
- It introduces a relaxation factor \( \omega \) (typically \( 1 < \omega < 2 \)) to potentially accelerate convergence.
- It iteratively updates the temperature at each node based on the latest available values from neighboring nodes until the solution converges within a specified tolerance or a maximum number of iterations is reached.

This iterative approach avoids the need to explicitly store and invert the large matrix \( A \). 