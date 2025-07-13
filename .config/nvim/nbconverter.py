import os
import sys

import nbformat


def ipynb_to_py(ipynb_path, py_path):
    """Convert .ipynb to .py with # CELL comments."""
    with open(ipynb_path, "r", encoding="utf-8") as f:
        notebook = nbformat.read(f, as_version=4)

    with open(py_path, "w", encoding="utf-8") as f:
        for cell in notebook.cells:
            if cell.cell_type == "code":
                f.write("# CELL\n")
                f.write(cell.source + "\n\n")


def py_to_ipynb(py_path, ipynb_path):
    """Convert .py with # CELL comments back to .ipynb."""
    if not os.path.exists(py_path):
        return

    with open(py_path, "r", encoding="utf-8") as f:
        lines = f.readlines()

    notebook = nbformat.v4.new_notebook()
    current_cell = []

    for line in lines:
        if line.strip() == "# CELL":
            if current_cell:
                notebook.cells.append(
                    nbformat.v4.new_code_cell("\n".join(current_cell))
                )
                current_cell = []
        else:
            current_cell.append(line.rstrip())

    # Add last cell if any content remains
    if current_cell:
        notebook.cells.append(nbformat.v4.new_code_cell("\n".join(current_cell)))

    # Write to .ipynb file
    with open(ipynb_path, "w", encoding="utf-8") as f:
        nbformat.write(notebook, f)


if __name__ == "__main__":
    action, input_path, output_path = sys.argv[1], sys.argv[2], sys.argv[3]
    if action == "to_py":
        ipynb_to_py(input_path, output_path)
    elif action == "to_ipynb":
        py_to_ipynb(input_path, output_path)
