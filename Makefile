# TODO: Figure out to integrate this stuff into the Rakefile?

terraform: localstack
	@cd terraform \
		&& terraform apply -auto-approve \
		|| terraform init \
		&& terraform apply -auto-approve

localstack: docker-desktop
	@docker compose up -d

docker-desktop:
	@if ! docker info > /dev/null 2>&1; then \
		docker desktop start; \
	fi

stripe-local-webhooks:
	@stripe listen --forward-to http://127.0.0.1:3000/webhooks/stripe
