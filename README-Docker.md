# Catmandu Docker

For a quick installation of Catmandu using [Docker](https://www.docker.com) use the following command:

```
docker run -it librecat/catmandu
```

Now you should be able to run Catmandu in the Docker terminal:

```
catmandu@d45e783d0bca:~$ catmandu help
```

To have access to your local files use one of the following commands:

Windows:

```
docker run -v C:\Users\yourname:/home/catmandu/Home -it librecat/catmandu
```

OSX:

```
docker run -v /Users/yourname:/home/catmandu/Home -it librecat/catmandu
```

Linux:

```
docker run -v /home/yourname:/home/catmandu/Home -it librecat/catmandu
```

For more information about the Catmandu extension that are available in the Docker image check the [docker-catmandu](https://github.com/LibreCat/docker-catmandu) project.