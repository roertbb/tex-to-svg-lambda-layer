FROM lambci/lambda-base-2:build

# The TeXLive installer needs md5 and wget.
RUN yum -y install perl-Digest-MD5 && \
    yum -y install wget

RUN mkdir /var/src
WORKDIR /var/src

# Download TeXLive installer.
# ADD http://mirror.ctan.org/systems/texlive/tlnet/install-tl-unx.tar.gz /var/src/
COPY install-tl-unx.tar.gz /var/src/

# Minimal TeXLive configuration profile.
COPY texlive.profile /var/src/

# Intstall base TeXLive system.
RUN tar xf install*.tar.gz
RUN cd install-tl-* && \
    ./install-tl --profile ../texlive.profile

ENV PATH=/var/task/texlive/bin/x86_64-linux/:$PATH

# install packages required for compiling the presentation
RUN tlmgr install ucs \ 
    polski \
    multirow \
    beamer \
    babel \
    babel-polish \
    pagesel \
    pgf \
    fp \
    calculator

# Install latexmk.
RUN tlmgr install latexmk

# Remove LuaTeX.
RUN tlmgr remove --force luatex

# Remove large unneeded files.
RUN rm -rf /var/task/texlive/tlpkg/texlive.tlpdb* \
    /var/task/texlive/texmf-dist/source/latex/koma-script/doc \
    /var/task/texlive/texmf-dist/doc

RUN mkdir -p /var/task/texlive/tlpkg/TeXLive/Digest/ && \
    mkdir -p /var/task/texlive/tlpkg/TeXLive/auto/Digest/MD5/ && \
    cp /usr/lib64/perl5/vendor_perl/Digest/MD5.pm \
    /var/task/texlive/tlpkg/TeXLive/Digest/ && \
    cp /usr/lib64/perl5/vendor_perl/auto/Digest/MD5/MD5.so \
    /var/task/texlive/tlpkg/TeXLive/auto/Digest/MD5

FROM lambci/lambda-base-2:build

WORKDIR /var/task

# Copy latex files
COPY --from=0 /var/task/ /var/task/

# Make it work with perl added in another layer - arn:aws:lambda:eu-central-1:292169987271:layer:AWSLambda-Perl5:18
RUN find /var/task/ -type f -exec sed -i 's/\/usr\/bin\/env perl/\/opt\/bin\/perl/g' {} \;

# Copy pdf2svg files
COPY pdf2svg/ /var/task/pdf2svg/

# Copy required libs for pdf2svg
RUN cp -R /lib64/libcrypt* /var/task/pdf2svg/lib/
RUN cp -R /lib64/libgio* /var/task/pdf2svg/lib/
RUN cp -R /lib64/libgobject* /var/task/pdf2svg/lib/
RUN cp -R /lib64/libglib* /var/task/pdf2svg/lib/
RUN cp -R /lib64/libgmodule* /var/task/pdf2svg/lib/
RUN cp -R /lib64/libmount* /var/task/pdf2svg/lib/
RUN cp -R /lib64/libexpat* /var/task/pdf2svg/lib/
RUN cp -R /lib64/libblkid* /var/task/pdf2svg/lib/
RUN cp -R /lib64/libuuid* /var/task/pdf2svg/lib/