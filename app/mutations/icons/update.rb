module Icons
  class Update < Mutations::Command
    AUTH_ERROR = 'You can\'t create garden crops for gardens you don\'t own.'

    required do
      model :icon
      model :user
      hash :attributes do
        optional do
          string :description
          string :name
          string :svg
        end
      end
    end

    optional do
      array :crops, class: Hash, arrayize: true
    end

    def validate
      @icon = icon
      validate_permissions
    end

    def execute
      @icon.update! attributes
      @icon.save
      @icon.reload
    end

    private

    def validate_permissions
        add_error :icon, :not_authorized, AUTH_ERROR unless icon.user == user
    end
  end
end
