import nbformat


def ipynb_to_py_content(ipynb_content):
    """Convert .ipynb content to Python-like content with # CELL comments."""
    notebook = nbformat.reads(ipynb_content, as_version=4)
    lines = []
    for cell in notebook.cells:
        if cell.cell_type == "code":
            lines.append("# CELL")
            lines.append(cell.source)
            lines.append("")  # Add a blank line between cells
    return "\n".join(lines)


def py_to_ipynb_content(py_content):
    """Convert Python-like content with # CELL comments back to .ipynb."""
    lines = py_content.splitlines()
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
            current_cell.append(line)

    if current_cell:
        notebook.cells.append(nbformat.v4.new_code_cell("\n".join(current_cell)))

    return nbformat.writes(notebook, version=4)


if __name__ == "__main__":
    import sys
    import os

    action = sys.argv[1]
    if action == "to_py":
        ipynb_path = sys.argv[2]
        with open(ipynb_path, "r", encoding="utf-8") as f:
            ipynb_content = f.read()
        print(ipynb_to_py_content(ipynb_content))
    elif action == "to_ipynb":
        py_path = sys.argv[2]
        with open(py_path, "r", encoding="utf-8") as f:
            py_content = f.read()
        print(py_to_ipynb_content(py_content))
