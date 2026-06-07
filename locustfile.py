from locust import HttpUser, task, between, LoadTestShape


class StagesShape(LoadTestShape):
    stages = [
        {"duration": 15, "users": 10, "spawn_rate": 5},
        {"duration": 30, "users": 50, "spawn_rate": 10},
        {"duration": 50, "users": 200, "spawn_rate": 20},
        {"duration": 80, "users": 500, "spawn_rate": 30},
        {"duration": 120, "users": 500, "spawn_rate": 30},
    ]

    def tick(self):
        run_time = self.get_run_time()
        for stage in self.stages:
            if run_time < stage["duration"]:
                return (stage["users"], stage["spawn_rate"])
        return None


class ApiUser(HttpUser):
    wait_time = between(0, 0.01)

    @task(3)
    def busca_simples(self):
        self.client.get("/dados")

    @task(2)
    def busca_data(self):
        self.client.get("/dados-data")

    @task(2)
    def busca_disposicao(self):
        self.client.get("/dados-disposicao")

    @task(1)
    def busca_texto(self):
        self.client.get("/dados-texto")

    @task(1)
    def busca_agregado(self):
        self.client.get("/dados-agregado")

    @task(1)
    def busca_ordenado(self):
        self.client.get("/dados-ordenado")

    @task(1)
    def busca_src(self):
        self.client.get("/dados-src")

    @task(1)
    def insere(self):
        self.client.post("/dados-inserir")

    @task(1)
    def contagem(self):
        self.client.get("/dados-contagem")
