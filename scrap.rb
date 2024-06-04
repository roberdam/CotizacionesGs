# Programa para escrapear datos de cotizaciones
require 'nokogiri'
require 'open-uri'
require 'csv'
require 'date'

# URL de la página de cotizaciones
url = 'https://www.dnit.gov.py/web/portal-institucional/cotizaciones'

# Nombres de los meses en español
MONTHNAMES_ES = ["", "Enero", "Febrero", "Marzo", "Abril", "Mayo", "Junio", "Julio", "Agosto", "Septiembre", "Octubre", "Noviembre", "Diciembre"]

# Método para obtener el contenido HTML de la página
def fetch_html(url)
  Nokogiri::HTML(URI.open(url))
end

# Método para extraer la información y generar los CSVs
def extract_and_generate_csv(url)
  doc = fetch_html(url)
  # Obtener todas las secciones de cotizaciones
  sections = doc.css('.component-table')

  sections.each do |section|
    # Obtener el título de la sección para determinar el mes y año
    title = section.css('h4.section__midtitle').text.strip
    month_year = title.match(/mes de (\w+) (\d{4})/i)
    next unless month_year

    month, year = month_year[1], month_year[2]
    month_number = MONTHNAMES_ES.index(month.capitalize).to_s.rjust(2, '0')

    # Crear el nombre del archivo CSV
    csv_filename = "#{year}.csv"

    # Verificar si el archivo ya existe para agregar encabezado si es necesario
    file_exists = File.exist?(csv_filename)

    # Crear un CSV o abrirlo si ya existe
    CSV.open(csv_filename, 'a') do |csv|
      # Escribir la cabecera si el archivo es nuevo
      unless file_exists
        csv << ['fecha', 'dolar_compra', 'dolar_venta', 'real_compra', 'real_venta',
                'peso_compra', 'peso_venta', 'yen_compra', 'yen_venta', 'euro_compra',
                'euro_venta', 'libra_compra', 'libra_venta']
      end

      # Obtener todas las filas de la tabla
      rows = section.css('table tbody tr')
      rows.each do |row|
        cols = row.css('td').map(&:text).map(&:strip)
        day = cols.shift
        date = "#{day}/#{month_number}/#{year[2..-1]}"

        # Convertir valores numéricos a flotantes con 2 decimales
        formatted_cols = cols.map do |col|
          col.gsub!('.', '')  # Eliminar puntos de miles
          col.gsub!(',', '.')  # Reemplazar coma decimal por punto
          '%.2f' % col.to_f  # Convertir a flotante y formatear con 2 decimales
        end

        csv << [date, *formatted_cols]
      end
    end
  end
end

# Ejecutar el método para extraer datos y generar CSVs
extract_and_generate_csv(url)
