from setuptools import setup

with open("README.md", "r", encoding="utf-8") as fh:
    long_description = fh.read()

setup(
    name="transito",
    version="0.2.0",
    author="Transito Team",
    description="HLS downloader CLI tool",
    long_description=long_description,
    long_description_content_type="text/markdown",
    url="https://github.com/yourusername/transito",
    py_modules=["transito"],
    entry_points={
        "console_scripts": [
            "transito=transito:main",
        ],
    },
    classifiers=[
        "Development Status :: 4 - Beta",
        "Intended Audience :: End Users/Desktop",
        "License :: OSI Approved :: MIT License",
        "Operating System :: OS Independent",
        "Programming Language :: Python :: 3",
        "Programming Language :: Python :: 3.10",
        "Programming Language :: Python :: 3.11",
        "Programming Language :: Python :: 3.12",
        "Programming Language :: Python :: 3.13",
        "Programming Language :: Python :: 3.14",
    ],
    python_requires=">=3.10",
    install_requires=[],
)
