require "open-uri"

class Recipe < ApplicationRecord
  after_save if: -> { saved_change_to_name? || saved_change_to_ingredients? } do
    set_content
    set_picture
  end

  has_one_attached :picture

  # Overwritte attribute method
  # def content
  #   if super.blank?
  #     set_content
  #   else
  #     super
  #   end
  # end

  private

  def set_content
      client = OpenAI::Client.new
      chaptgpt_response = client.chat(parameters: {
        model: "gpt-3.5-turbo",
        messages: [{ role: "user", content: "Give me a simple recipe for #{name} with the ingredients #{ingredients}. Give me only the text of the recipe, without any of your own answer like 'Here is a simple recipe'."}]
      })
      new_content = chaptgpt_response.dig("choices", 0, "message", "content")
      update(content: new_content)
      return new_content
  end

  def set_picture
    client = OpenAI::Client.new
    response = client.images.generate(parameters: {
      prompt: "A recipe image of #{name}", size: "256x256"
    })

    url = response.dig("data", 0, "url")
    file = URI.open(url)

    picture.purge if picture.attached?
    picture.attach(io: file, filename: "#{name}_ai_generated_img.jpg", content_type: "image/png")
  end
end
