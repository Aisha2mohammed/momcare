const { Model, DataTypes } = require('sequelize');

module.exports = (sequelize) => {
  class EmergencyContact extends Model {}

  EmergencyContact.init({
    id: {
      type: DataTypes.UUID,
      defaultValue: DataTypes.UUIDV4,
      primaryKey: true
    },
    mother_id: {
      type: DataTypes.UUID,
      allowNull: false
    },
    contact_name: {
      type: DataTypes.STRING(255),
      allowNull: false
    },
    phone: {
      type: DataTypes.STRING(50),
      allowNull: false
    },
    relationship: {
      type: DataTypes.STRING(100)
    }
  }, {
    sequelize,
    modelName: 'EmergencyContact',
    tableName: 'emergency_contacts',
    timestamps: true,
    createdAt: 'created_at',
    updatedAt: false
  });

  EmergencyContact.associate = (models) => {
    EmergencyContact.belongsTo(models.User, {
      foreignKey: 'mother_id',
      as: 'mother'
    });
  };

  return EmergencyContact;
};
