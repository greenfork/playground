# Data model

Client:

- id: client:ULID
- name
- startedAt: Date
- lastActivityAt: DateTime
- sessionCount: integer
- bio: text
- type: client
- createdAt: DateTime

Note:

- id: note:ULID
- body: text
- sessionAt: Date
- createdAt: DateTime
- type: note
- clientId: client:ULID
- status: draft, final

Payment:

- id: payment:ULID
- type: payment
- createdAt: DateTime
- paidAt: Date
- amount: integer
- currency: string
- clientId: client:ULID
