#!/bin/bash


declare myvar='hello, world'


echo "${myvar##hello, }"
echo "${myvar/hello, /hi there, }"

