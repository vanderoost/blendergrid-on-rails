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

live-test:
	@while :; do \
		find {app,test} \( -iname '*.rb' -o -iname '*.yml' \) | \
		entr -cd bash -c 'rails test' && break; \
	done
