
clean:
	@rm -rf ./public 
	@rm -rf ./resources
	@echo "deleted public & resources"
	
serve:
	@./serve-local.sh
