Examples [here](https://crontab.guru/examples.html)

Crontab layout:

    crontab -e

    # m h dom mon dow command
    * * * * * command to be executed
    – – – – –
    | | | | |
    | | | | +—– day of week (0 – 6) (Sunday=0)
    | | | +——- month (1 – 12)
    | | +——— day of month (1 – 31)
    | +———– hour (0 – 23)
    +————- min (0 – 59)

Run a job every 4 hours:

    0 */4 * * * /path/to/script.sh

Midnight:

    0 0 * * *

1AM:

    0 1 * * *

