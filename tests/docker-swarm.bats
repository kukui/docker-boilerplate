setup () {
    load utils
    export $(cat environments/$ENVIRONMENT | grep -v ^# | xargs)
    make swarmup
}

teardown () {
    make swarmdown
}


