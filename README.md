# Дипломный проект по DevOps

## 1. Введение и описание проекта

Этот проект создан для демонстрации навыков DevOps через автоматизацию развёртывания инфраструктуры и мониторинга. Основная цель — показать, как использовать современные инструменты для управления облачными системами и процессами разработки.

### Основные задачи:
- Развёртывание инфраструктуры в Яндекс.Облаке с помощью Terraform.
- Настройка Kubernetes-кластера для управления контейнерами.
- Установка мониторинга с использованием Prometheus и Grafana.
- Автоматизация процессов через CI/CD с GitHub Actions.

### Технологии:
- **Terraform**: Инфраструктура как код.
- **Kubernetes**: Оркестрация контейнеров.
- **Prometheus и Grafana**: Мониторинг и визуализация.
- **GitHub Actions**: CI/CD.
- **Яндекс.Облако**: Облачная платформа.

---

## 2. Инфраструктура на Terraform

Инфраструктура включает виртуальную сеть (VPC), мастер-ноду и две воркер-ноды в Яндекс.Облаке, а также S3-бэкенд для хранения состояния Terraform.

### Команды для развёртывания:
1. Инициализация Terraform:
   ```bash
   terraform init
   ```
    ![Terraform init](https://github.com/MezencevPavel/diploma-devops/blob/main/img/1.2%20terraform_init.png)

2. Применение конфигурации:
   ```bash
   terraform apply -auto-approve
   ```
    ![Terraform apply](https://github.com/MezencevPavel/diploma-devops/blob/main/img/1.1%20terraform%20apply.png)

### Пример кода Terraform

#### Виртуальная сеть и подсети:
```tf
resource "yandex_vpc_network" "diploma_vpc" {
  name = "diploma-vpc"
}

resource "yandex_vpc_subnet" "subnet_a" {
  name           = "subnet-a"
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.diploma_vpc.id
  v4_cidr_blocks = ["10.0.1.0/24"]
}

resource "yandex_vpc_subnet" "subnet_b" {
  name           = "subnet-b"
  zone           = "ru-central1-b"
  network_id     = yandex_vpc_network.diploma_vpc.id
  v4_cidr_blocks = ["10.0.2.0/24"]
}

resource "yandex_vpc_subnet" "subnet_d" {
  name           = "subnet-d"
  zone           = "ru-central1-d"
  network_id     = yandex_vpc_network.diploma_vpc.id
  v4_cidr_blocks = ["10.0.3.0/24"]
}
```

#### Мастер-нода:
```tf
resource "yandex_compute_instance" "k8s_master" {
  name        = "k8s-master"
  platform_id = "standard-v3"
  zone        = "ru-central1-a"

  resources {
    cores  = 2
    memory = 4
  }

  boot_disk {
    initialize_params {
      image_id = "fd8kdq0qsgtgi32j9ljb"  # Ubuntu 20.04
      size     = 20
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.subnet_a.id
    nat       = true
  }

  metadata = {
    ssh-keys = "ubuntu:${file("~/.ssh/id_rsa.pub")}"
  }
}
```

#### Воркер-ноды:
```tf
resource "yandex_compute_instance" "k8s_worker" {
  count       = 2
  name        = "k8s-worker-${count.index + 1}"
  platform_id = "standard-v3"
  zone        = element(["ru-central1-b", "ru-central1-d"], count.index)

  resources {
    cores  = 2
    memory = 4
  }

  boot_disk {
    initialize_params {
      image_id = "fd8kdq0qsgtgi32j9ljb"
      size     = 20
    }
  }

  network_interface {
    subnet_id = element([yandex_vpc_subnet.subnet_b.id, yandex_vpc_subnet.subnet_d.id], count.index)
    nat       = true
  }

  metadata = {
    ssh-keys = "ubuntu:${file("~/.ssh/id_rsa.pub")}"
  }
}
```

#### S3-бэкенд:
```tf
terraform {
  backend "s3" {
    endpoints = {
      s3 = "https://storage.yandexcloud.net"
    }
    bucket     = "diploma-tf-state"
    region     = "ru-central1"
    key        = "terraform.tfstate"
    access_key = "x"
    secret_key = "x"
    skip_region_validation      = true
    skip_credentials_validation = true
    skip_requesting_account_id  = true
    skip_metadata_api_check     = true
  }
}
```

---

## 3. Настройка Kubernetes

Kubernetes устанавливается на мастер- и воркер-ноды после создания инфраструктуры.

### Команды для настройки:
1. Подключение к мастер-ноде по SSH с пользователем ubuntu по ключу RSA
   
2. Установка kubeadm, kubelet и kubectl:
   ```bash
   sudo apt-get update
   sudo apt-get install -y apt-transport-https ca-certificates curl
   curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
   sudo bash -c 'echo "deb [arch=amd64] http://apt.kubernetes.io/ kubernetes-xenial main" > /etc/apt/sources.list.d/kubernetes.list'
   sudo apt-get update
   sudo apt-get install -y kubelet=1.30.0-00 kubeadm=1.30.0-00 kubectl=1.30.0-00
   sudo apt-mark hold kubelet kubeadm kubectl
   ```
3. Инициализация кластера:
   ```bash
   sudo kubeadm init --pod-network-cidr=10.244.0.0/16
   ```
4. Настройка kubectl:
   ```bash
   mkdir -p $HOME/.kube
   sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
   sudo chown $(id -u):$(id -g) $HOME/.kube/config
   ```
5. Установка сети (Calico):
   ```bash
   kubectl apply -f https://docs.projectcalico.org/v3.20/manifests/calico.yaml
   ```
6. Присоединение воркер-нод:
   - На мастер-ноде:
     ```bash
     sudo kubeadm token create --print-join-command
     ```
   - На каждой воркер-ноде:
     ```bash
     sudo kubeadm join <master_ip>:6443 --token <token> --discovery-token-ca-cert-hash sha256:<hash>
     ```

    ![install worker and master](https://github.com/MezencevPavel/diploma-devops/blob/main/img/1.8%20install%20worker%20and%20master.png) 

    ![install kuber ](https://github.com/MezencevPavel/diploma-devops/blob/main/img/1.9%20install%20kuber%20.png) 

    ![install kuber2](https://github.com/MezencevPavel/diploma-devops/blob/main/img/2.0%20install%20kuber2.png)

    ![install kub](https://github.com/MezencevPavel/diploma-devops/blob/main/img/2.1%20install%20kub.png)

    ![Kub Klasater](https://github.com/MezencevPavel/diploma-devops/blob/main/img/2.2%20Kub%20Klasater.png)

---

## 4. Мониторинг с Prometheus и Grafana

Для наблюдения за кластером и приложениями используются Prometheus и Grafana.

### Команды для установки:
1. Создание пространства имён:
   ```bash
   kubectl create namespace monitoring
   ```
2. Установка Prometheus:
   ```bash
   helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
   helm repo update
   helm install prometheus prometheus-community/prometheus -n monitoring
   ```
3. Установка Grafana:
   ```bash
   helm repo add grafana https://grafana.github.io/helm-charts
   helm repo update
   helm install grafana grafana/grafana -n monitoring
   ```
4. Доступ к Grafana:
   - Получение пароля:
     ```bash
     kubectl get secret --namespace monitoring grafana -o jsonpath="{.data.admin-password}" | base64 --decode ; echo
     ```
   - Проброс порта:
     ```bash
     kubectl port-forward --namespace monitoring svc/grafana 3000:80
     ```
   - Откройте `http://localhost:3000`, логин: `admin`, пароль из команды выше.
   - Добавьте Prometheus как источник данных: `http://prometheus-server.monitoring.svc.cluster.local`.

![Grafana](https://github.com/MezencevPavel/diploma-devops/blob/main/img/4.1%20Grafana.png)

![Grafana-Dashboard](https://github.com/MezencevPavel/diploma-devops/blob/main/img/4.2%20Grafana-Dashboard.png)

![Grafana-Dashboard2](https://github.com/MezencevPavel/diploma-devops/blob/main/img/4.3%20Grafana-Dashboard2.png)


---

## 5. CI/CD на GitHub Actions

CI/CD автоматизирует проверку и развёртывание инфраструктуры при изменениях в репозитории.

### Пример `.github/workflows/ci-cd.yml`:
```yaml
name: CI/CD Pipeline

on:
  push:
    branches:
      - main
  pull_request:
    branches:
      - main

jobs:
  terraform-apply:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v4
      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v3
        with:
          terraform_version: 1.9.0
      - name: Terraform Init
        env:
          YANDEX_TOKEN: ${{ secrets.YANDEX_TOKEN }}
          YANDEX_ACCESS_KEY: ${{ secrets.YANDEX_ACCESS_KEY }}
          YANDEX_SECRET_KEY: ${{ secrets.YANDEX_SECRET_KEY }}
        run: terraform init
      - name: Terraform Apply
        env:
          YANDEX_TOKEN: ${{ secrets.YANDEX_TOKEN }}
          YANDEX_ACCESS_KEY: ${{ secrets.YANDEX_ACCESS_KEY }}
          YANDEX_SECRET_KEY: ${{ secrets.YANDEX_SECRET_KEY }}
        run: terraform apply -auto-approve
```

### Настройка секретов:
1. Перейдите в `Settings > Secrets and variables > Actions`.
2. Добавьте:
   - `YANDEX_TOKEN`
   - `YANDEX_ACCESS_KEY`
   - `YANDEX_SECRET_KEY`

---

## 6. Установка и использование

1. Клонирование репозитория:
   ```bash
   git clone https://github.com/<your-username>/<your-repo>.git
   cd <your-repo>
   ```
2. Установка Terraform:
   - Следуйте [инструкции](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli).
3. Настройка SSH:
   ```bash
   ssh-keygen -t rsa -b 4096
   ```
4. Развёртывание:
   ```bash
   terraform init
   terraform apply -auto-approve
   ```
5. Проверка кластера:
   ```bash
   ssh ubuntu@<master_ip>
   kubectl get nodes
   ```

---

## 7. Заключение

В данном проекте были успешно реализованы ключевые практики DevOps:
- Полностью автоматизировано развертывание инфраструктуры в Яндекс.Облаке с использованием Terraform
- Настроен отказоустойчивый Kubernetes-кластер с мастер-нодой и двумя воркер-нодами
- Внедрена система мониторинга на базе Prometheus и Grafana
- Реализован CI/CD-пайплайн с помощью GitHub Actions

Проект демонстрирует полный цикл DevOps-практик от инфраструктуры до мониторинга.

## 8. Благодарности

Выражаю искреннюю благодарность:
- Образовательной онлайн-платформе Нетология
- Преподавателям курса DevOps
- Кураторам и наставникам программы

## 9. Контакты

- ✉️ **Email**: [paveldevopsp@gmail.com](mailto:paveldevopsp@gmail.com)
- 🐙 **GitHub**: [github.com/MezencevPavel](https://github.com/MezencevPavel)
- 🐳 **Docker Hub**: [hub.docker.com/u/mezencevpavel](https://hub.docker.com/u/mezencevpavel)
