# NASC

NASC is an AI-powered support assistant for parents and caregivers of autistic children.

## Technology Stack

- Python and FastAPI
- PostgreSQL and SQLAlchemy
- Pydantic AI and Google Gemini
- Telegram Bot API
- AWS and Terraform
- Docker and GitHub Actions

## Telegram Integration

The Telegram integration supports:

- Private conversations with the bot.
- Account linking and user authorization.
- Incoming text and voice messages.
- Audio transcription using Google Gemini.
- Conversation history and context preservation.
- Text responses regardless of the incoming message type.

### Voice Message Limits

| Parameter                       | Default     |
| ------------------------------- | ----------- |
| Audio format                    | OGG/Opus    |
| Maximum file size               | 5 MiB       |
| Maximum duration                | 300 seconds |
| Download timeout                | 30 seconds  |
| Transcription timeout per model | 60 seconds  |
| Total transcription timeout     | 180 seconds |
| Chat timeout per model          | 60 seconds  |
| Total chat timeout              | 180 seconds |

Audio attachments, documents, and videos are not supported.

Audio files are processed in memory without permanent audio storage. Transcriptions are stored as text in the conversation history.

## AI Configuration

Chat and transcription use independent, ordered lists of Gemini models:

- `GEMINI_CHAT_MODELS`
- `GEMINI_TRANSCRIPTION_MODELS`

The first model is the primary model. Subsequent models are fallback options.

See `backend/.env.example` for available environment variables and default processing limits.

## Deployment

The development environment uses AWS infrastructure managed by Terraform and automated deployment through GitHub Actions.

The chat and transcription model lists are configured through GitHub Actions repository variables.

Sensitive credentials are managed through AWS Secrets Manager.
