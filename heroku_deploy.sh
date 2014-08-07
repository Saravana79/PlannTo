#!/bin/sh
heroku run rake resque:pause
git push heroku master
heroku run rake resque:resume
