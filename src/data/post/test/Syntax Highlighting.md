---
publishDate: 2026-01-02
title: 'Test Syntax Highlighting'
topic: 'software'
tags:
  - test
draft: false
accessLevel: 'public'
---

# Syntax Highlighting

This file shows syntax hightlighting.

## Features

- Code execution and output
- Data visualization
- Mathematical equations
- Markdown cells

```python
# Simple Python code example
import numpy as np
import matplotlib.pyplot as plt

# Generate some data
x = np.linspace(0, 2*np.pi, 100)
y = np.sin(x)

print(f"Generated {len(x)} data points")
print(f"Min value: {y.min():.3f}, Max value: {y.max():.3f}")
```

## Visualization

Let's create a simple plot:

```python
plt.figure(figsize=(10, 6))
plt.plot(x, y, 'b-', linewidth=2, label='sin(x)')
plt.plot(x, np.cos(x), 'r--', linewidth=2, label='cos(x)')
plt.xlabel('x')
plt.ylabel('y')
plt.title('Trigonometric Functions')
plt.legend()
plt.grid(True, alpha=0.3)
plt.show()
```

## Mathematical Equations

The wave equation:

$$\frac{\partial^2 u}{\partial t^2} = c^2 \nabla^2 u$$

Where $c$ is the wave speed and $\nabla^2$ is the Laplacian operator.

## Conclusion

This notebook demonstrates the integration of:

- **Code execution**: Python code with numpy and matplotlib
- **Output display**: Print statements and visualizations
- **LaTeX equations**: Mathematical notation
- **Rich markdown**: Headers, lists, and formatting
