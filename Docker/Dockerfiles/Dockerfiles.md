A Dockerfile is a text file containing instructions to build a Docker image. It defines:

- Base image (FROM)

- Dependencies (RUN, COPY, etc.)

- Application code (COPY)

- Working directory (WORKDIR)

- Build commands (RUN)

- Startup command (CMD or ENTRYPOINT)

Multi-stage builds use multiple FROM instructions in one Dockerfile. Each stage has its own base image. You build your app in one stage (with dependencies), then copy only the final artifacts (binaries, JARs, etc.) into a smaller runtime image.

- Smaller final images

- No build tools in production container

- More secure and efficient


**CMD**
- Specifies the default arguments to the container's entrypoint.
- Can be overridden	when you run docker run myapp ...

```
FROM python:3.11
COPY app.py .
CMD ["python", "app.py"]

# override using 
docker run my-python-app python other.py
```

**ENTRYPOINT**
- Defines the main executable (i.e., the actual command to run).
  
```
FROM python:3.11
COPY app.py .
ENTRYPOINT ["python", "app.py"]

# When you run 
docker run my-python-app other.py

# becomes python app.py other.py (you can’t replace the ENTRYPOINT command)

```

**ENTRYPOINT + CMD**

- ENTRYPOINT is the base command
- CMD is the default argument
```
FROM python:3.11
ENTRYPOINT ["python"]
CMD ["app.py"]

# when you run 
docker run my-python-app other.py

# it will be 
python other.py
```

**Shell vs Exec Form**

- Exec form (recommended):
  - `ENTRYPOINT ["python", "app.py"]`
  - No shell involved.
  - Signals (e.g., CTRL+C) are passed correctly to child process.

- Shell form:
  - `ENTRYPOINT python app.py`
  - Runs via /bin/sh -c
  - Signal handling and quoting can be tricky




