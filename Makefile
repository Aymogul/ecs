.PHONY: up down logs clean hero test

up:
	cp -n .env.example .env || true
	docker compose up -d --build

down:
	docker compose down

logs:
	docker compose logs -f app worker temporal

hero:
	python3 scripts/make_hero.py

test:
	docker compose run --rm app pytest

clean:
	docker compose down -v

