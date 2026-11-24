workspace "Мессенджер" "Архитектурная модель мессенджера" {

    model {
        user = person "Пользователь" "Общается в личных и групповых чатах"
        admin = person "Администратор" "Управляет пользователями и системой"

        push = softwareSystem "Push-сервис" "Отправляет уведомления пользователям" {
            tags "External"
        }

        auth = softwareSystem "Сервис аутентификации" "Проверяет учётные данные пользователей" {
            tags "External"
        }

        messenger = softwareSystem "Мессенджер" "Обмен сообщениями между пользователями" {

            web = container "Веб-клиент" "Интерфейс для общения в браузере" "React"

            mobile = container "Мобильное приложение" "Общение со смартфона" "Kotlin / Swift"

            api = container "Backend API" "Бизнес-логика и обработка запросов" "Java / Spring Boot" {

                authController = component "AuthController" "Обработка запросов аутентификации" "Spring MVC"
                chatController = component "ChatController" "Управление чатами" "Spring MVC"
                messageController = component "MessageController" "Обработка отправки сообщений" "Spring MVC"

                authService = component "AuthService" "Проверка учётной записи" "Java"
                chatService = component "ChatService" "Создание и управление чатами" "Java"
                messageService = component "MessageService" "Создание и отправка сообщений" "Java"

                chatRepository = component "ChatRepository" "Доступ к данным чатов" "Spring Data"
                messageRepository = component "MessageRepository" "Доступ к сообщениям" "Spring Data"

                eventPublisher = component "EventPublisher" "Публикация событий доставки" "Spring AMQP"
            }

            worker = container "Обработчик сообщений" "Фоновая доставка сообщений" "Java"

            db = container "Основная БД" "Пользователи, чаты и сообщения" "PostgreSQL" {
                tags "Database"
            }

            queue = container "Очередь сообщений" "Хранение событий доставки" "RabbitMQ" {
                tags "Queue"
            }
        }

        user -> messenger.web "Пользуется" "HTTPS"
        user -> messenger.mobile "Пользуется" "HTTPS"
        admin -> messenger.web "Управляет системой" "HTTPS"

        messenger.web -> messenger.api "Отправляет запросы" "JSON/HTTPS"
        messenger.mobile -> messenger.api "Отправляет запросы" "JSON/HTTPS"

        messenger.api -> messenger.db "Читает и записывает данные" "JDBC"
        messenger.api -> messenger.queue "Публикует события" "AMQP"
        messenger.queue -> messenger.worker "Передаёт события" "AMQP"
        messenger.worker -> messenger.db "Обновляет статусы сообщений" "JDBC"
        messenger.worker -> push "Отправляет уведомления" "HTTPS"
        messenger.api -> auth "Проверяет пользователя" "HTTPS"

        messenger.web -> messenger.api.authController "Вызывает" "JSON/HTTPS"
        messenger.web -> messenger.api.chatController "Вызывает" "JSON/HTTPS"
        messenger.web -> messenger.api.messageController "Вызывает" "JSON/HTTPS"

        messenger.mobile -> messenger.api.messageController "Вызывает" "JSON/HTTPS"

        messenger.api.authController -> messenger.api.authService "Вызывает"
        messenger.api.chatController -> messenger.api.chatService "Вызывает"
        messenger.api.messageController -> messenger.api.messageService "Вызывает"

        messenger.api.chatService -> messenger.api.chatRepository "Использует"
        messenger.api.messageService -> messenger.api.messageRepository "Использует"
        messenger.api.messageService -> messenger.api.eventPublisher "Публикует событие"

        messenger.api.chatRepository -> messenger.db "Читает и записывает" "JDBC"
        messenger.api.messageRepository -> messenger.db "Читает и записывает" "JDBC"
        messenger.api.eventPublisher -> messenger.queue "Отправляет событие" "AMQP"
    }

    views {
        systemContext messenger "Context" {
            include *
            autolayout lr
        }

        container messenger "Containers" {
            include *
            autolayout lr
        }

        component messenger.api "Components" {
            include *
            autolayout lr
        }

        theme default
    }
}
