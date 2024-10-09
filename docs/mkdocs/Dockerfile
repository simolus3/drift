# This Docker file is used to build the mkdocs image for the documentation
FROM squidfunk/mkdocs-material:9
RUN apk add --no-cache g++
RUN apk add --no-cache gcc
RUN pip install mkdocs-macros-plugin
RUN pip install mkdocs-git-revision-date-localized-plugin
RUN pip install mkdocs-autorefs