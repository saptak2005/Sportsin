# Sportsin

**The social media platform for athletes and recruiters.**

Sportsin is a comprehensive social media application designed to connect the sports world. Players can showcase their talents, build their careers, and connect with opportunities. Recruiters can discover promising athletes, post job openings, and manage tournaments.

## Table of Contents

- [About The Project](#about-the-project)
- [Features](#features)
- [Tech Stack](#tech-stack)
- [Getting Started](#getting-started)
- [Project Structure](#project-structure)
- [Contributing](#contributing)
- [License](#license)
- [Contact](#contact)

## About The Project

Sportsin aims to bridge the gap between athletes and recruiters, providing a dedicated platform for career development and talent acquisition in the sports industry. This project is built with a modern tech stack, featuring a Flutter-based mobile application and a Go-powered backend.

## Features

### For Players

-   **Profile Management:** Create and manage a detailed profile, including personal information, sports statistics, and achievements.
-   **Post Updates:** Share posts, images, and videos to showcase your skills and journey.
-   **Certificate Upload:** Upload and display certificates and awards.
-   **Tournament Participation:** Discover and apply for tournaments.
-   **Job Applications:** Find and apply for job openings posted by recruiters.
-   **Networking:** Connect and chat with other players and recruiters.

### For Recruiters

-   **Company Profile:** Create and manage a profile for your organization.
-   **Player Search:** Search for and filter players based on various criteria.
-   **Job Postings:** Create and manage job openings.
-   **Tournament Creation:** Organize and manage tournaments.
-   **Content Sharing:** Post updates and news to your network.

## Tech Stack

### Frontend (Mobile App)

-   **Framework:** [Flutter](https://flutter.dev/)
-   **HTTP Client:** [Dio](https://pub.dev/packages/dio)
-   **Routing:** [go_router](https://pub.dev/packages/go_router)
-   **Secure Storage:** [flutter_secure_storage](https://pub.dev/packages/flutter_secure_storage)
-   **Push Notifications:** [Firebase Cloud Messaging](https://firebase.google.com/docs/cloud-messaging)

### Backend

-   **Language:** [Go](https://golang.org/)
-   **Framework:** [Gin](https://gin-gonic.com/)

### Database & Cache

-   **Database:** [PostgreSQL](https://www.postgresql.org/)
-   **Cache:** [Redis](https://redis.io/)

### Deployment

-   **Cloud Provider:** [Amazon Web Services (AWS)](https://aws.amazon.com/)
-   **Containerization:** [EC2 Container Service](https://aws.amazon.com/ecs/)

## Getting Started

To get a local copy up and running, follow these simple steps.

### Prerequisites

-   Flutter SDK
-   Go
-   Docker (for database and cache)

### Installation

1.  **Clone the repo**
    ```sh
    git clone https://github.com/your_username_/sportsin.git
    ```
2.  **Set up the backend**
    -   Navigate to the `backend` directory.
    -   Install dependencies: `go mod tidy`
    -   Run the backend server: `go run main.go`
3.  **Set up the frontend**
    -   Navigate to the `frontend` directory.
    -   Install dependencies: `flutter pub get`
    -   Run the app: `flutter run`

## Project Structure

```
.
├── backend/
│   ├── go.mod
│   └── main.go
└── frontend/
    ├── pubspec.yaml
    ├── lib/
    │   ├── main.dart
    │   └── ...
    └── ...
```

## Contributing

Contributions are what make the open-source community such an amazing place to learn, inspire, and create. Any contributions you make are **greatly appreciated**.

1.  Fork the Project
2.  Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3.  Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4.  Push to the Branch (`git push origin feature/AmazingFeature`)
5.  Open a Pull Request

## License

Distributed under the MIT License. See `LICENSE` for more information.


