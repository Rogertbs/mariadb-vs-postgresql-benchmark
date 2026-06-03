from locust import HttpUser, task, between


class ApiUser(HttpUser):
    wait_time = between(1, 3)

    @task
    def buscar_dados(self):
        self.client.get("/dados")
