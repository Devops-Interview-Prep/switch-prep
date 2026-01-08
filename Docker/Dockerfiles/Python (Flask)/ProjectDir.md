```
myapp/
├── Dockerfile
├── requirements.txt
├── setup.py                  # optional (for packaging)
├── .env                      # optional (for environment config)
├── app/                      # your actual application code
│   ├── __init__.py
│   ├── main.py
│   ├── routes.py             # for Flask
│   └── ...
├── tests/
│   └── test_main.py
└── run.py                    # entrypoint for Flask/Django/etc.
```
